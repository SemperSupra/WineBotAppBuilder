import asyncio
import socket
import uuid
import logging
from typing import Dict, List, Optional, cast

try:
    from zeroconf import IPVersion, ServiceInfo, Zeroconf, ServiceBrowser, ServiceStateChange
    HAS_ZEROCONF = True
except ImportError:
    HAS_ZEROCONF = False

logger = logging.getLogger("wbab.discovery")

class DiscoveryManager:
    SERVICE_TYPE = "_wbab-api._tcp.local."

    def __init__(
        self, 
        base_name: str = "WBAB-Daemon", 
        version: str = "1.0.0",
        instance_id: Optional[str] = None
    ):
        if not HAS_ZEROCONF:
            raise ImportError("zeroconf library is required for DiscoveryManager. Install with: pip install zeroconf")
        self.base_name = base_name
        self.version = version
        self.instance_id = instance_id or str(uuid.uuid4())
        self.zc: Optional[Zeroconf] = None
        self.service_info: Optional[ServiceInfo] = None
        self._peers: Dict[str, Dict] = {}

    def _get_ip(self) -> str:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            # doesn't even have to be reachable
            s.connect(('10.255.255.255', 1))
            IP = s.getsockname()[0]
        except Exception:
            IP = '127.0.0.1'
        finally:
            s.close()
        return IP

    async def find_existing_instances(self, timeout: float = 2.0) -> List[Dict]:
        """Scans the network for existing WBAB services."""
        if not HAS_ZEROCONF:
            return []
        zc = Zeroconf(ip_version=IPVersion.V4Only)
        found = []

        def on_service_state_change(zeroconf: 'Zeroconf', service_type: str, name: str, state_change: 'ServiceStateChange') -> None:
            if state_change is ServiceStateChange.Added:
                info = zeroconf.get_service_info(service_type, name)
                if info:
                    props = {k.decode(): v.decode() if isinstance(v, bytes) else v for k, v in info.properties.items()}
                    found.append({
                        "name": name,
                        "address": socket.inet_ntoa(info.addresses[0]),
                        "port": info.port,
                        "instance_id": props.get("instance_id"),
                        "version": props.get("version")
                    })

        browser = ServiceBrowser(zc, self.SERVICE_TYPE, handlers=[on_service_state_change])
        await asyncio.sleep(timeout)
        zc.close()
        return found

    async def start_announcing(self, port: int, allow_multi: bool = False):
        """Probes name, handles collisions, and registers the service."""
        if not allow_multi:
            existing = await self.find_existing_instances()
            for inst in existing:
                if inst["instance_id"] != self.instance_id:
                    raise RuntimeError(f"ConflictError: Another WBAB instance ({inst['name']}) is active at {inst['address']}:{inst['port']}")

        self.zc = Zeroconf(ip_version=IPVersion.V4Only)
        
        # Collision handling for name
        current_name = self.base_name
        suffix = 1
        while True:
            full_name = f"{current_name}.{self.SERVICE_TYPE}"
            info = self.zc.get_service_info(self.SERVICE_TYPE, full_name)
            if not info:
                break
            suffix += 1
            current_name = f"{self.base_name}-{suffix}"

        desc = {
            "version": self.version,
            "mode": "multi" if allow_multi else "singleton",
            "instance_id": self.instance_id,
        }

        self.service_info = ServiceInfo(
            self.SERVICE_TYPE,
            f"{current_name}.{self.SERVICE_TYPE}",
            addresses=[socket.inet_aton(self._get_ip())],
            port=port,
            properties=desc,
            server=f"{current_name}.local.",
        )

        logger.info(f"Registering service: {current_name} on port {port}")
        self.zc.register_service(self.service_info)

    def stop_announcing(self):
        if self.zc:
            if self.service_info:
                self.zc.unregister_service(self.service_info)
            self.zc.close()
            self.zc = None

class DiscoveryBrowser:
    """Client-side helper to discover and track WBAB peers."""
    def __init__(self):
        if not HAS_ZEROCONF:
            raise ImportError("zeroconf library is required for DiscoveryBrowser. Install with: pip install zeroconf")
        self.zc = Zeroconf(ip_version=IPVersion.V4Only)
        self.found_peers: Dict[str, Dict] = {}

    def on_service_state_change(self, zeroconf: 'Zeroconf', service_type: str, name: str, state_change: 'ServiceStateChange') -> None:
        if not HAS_ZEROCONF:
            return
        if state_change is ServiceStateChange.Added:
            info = zeroconf.get_service_info(service_type, name)
            if info:
                props = {k.decode(): v.decode() if isinstance(v, bytes) else v for k, v in info.properties.items()}
                self.found_peers[name] = {
                    "name": name,
                    "address": socket.inet_ntoa(info.addresses[0]),
                    "port": info.port,
                    "version": props.get("version"),
                    "mode": props.get("mode")
                }
        elif state_change is ServiceStateChange.Removed:
            if name in self.found_peers:
                del self.found_peers[name]

    async def discover(self, timeout: float = 3.0) -> List[Dict]:
        browser = ServiceBrowser(self.zc, DiscoveryManager.SERVICE_TYPE, handlers=[self.on_service_state_change])
        await asyncio.sleep(timeout)
        return list(self.found_peers.values())

    def close(self):
        self.zc.close()
