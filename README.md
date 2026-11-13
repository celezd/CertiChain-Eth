# CertiChain – Credenciales académicas verificables en Ethereum

Proyecto Final del curso Introducción a Ethereum y Solidity - ETH Kipu

Integrantes: María Celeste Dominguez

**Demo:** [Probar la aplicación](https://celezd.github.io/CertiChain-Eth/)
Para verificar un certificado, subí el archivo `Certificado_de_prueba.pdf` (incluido en este repositorio) en el bloque "Verificar un certificado".

## ¿Qué problema resuelve?

Verificar que un título o certificado es auténtico hoy depende de contactar a la institución emisora y confiar en su base de datos centralizada. CertiChain registra en Ethereum la **huella digital (hash)** de cada certificado, de modo que cualquiera pueda verificarlo en segundos, sin permisos y sin depender de un intermediario.

> La blockchain prueba que el registro no fue alterado y quién lo firmó; no prueba que lo certificado sea verdadero. Por eso solo emisores autorizados pueden registrar.

## Cómo funciona

- `CertificateRegistry.sol` guarda en un `mapping(bytes32 => Certificate)` el emisor, la fecha, el titular y el estado (vigente/revocado).
- **No se guardan datos personales ni documentos on-chain**, solo hashes.
- El `metadataURI` (un enlace opcional a información adicional del certificado) se emite en el evento `CertificateIssued`, no en storage, para ahorrar gas.
- Control de acceso con `AccessControl` de OpenZeppelin:
  - `DEFAULT_ADMIN_ROLE`: administra emisores y puede revocar.
  - `ISSUER_ROLE`: puede emitir y revocar sus propios certificados.

| Función | Quién | Descripción |
|---|---|---|
| `issueCertificate(hash, recipient, uri)` | Emisor | Registra un certificado (escritura) |
| `revokeCertificate(hash)` | Emisor original / admin | Marca el certificado como revocado |
| `verifyCertificate(hash)` | Cualquiera | Devuelve existencia, vigencia, emisor, titular y fecha (lectura gratuita) |
| `grantRole(ISSUER_ROLE, cuenta)` | Admin | Autoriza una institución |

## Despliegue en Sepolia con Remix

1. Instalar MetaMask, habilitar testnets y obtener ETH de prueba en un faucet de Sepolia.
2. Abrir [Remix IDE](https://remix.ethereum.org) y crear `CertificateRegistry.sol` con el código de este repositorio (Remix resuelve el import de OpenZeppelin).
3. Compilar con Solidity `0.8.20` o superior.
4. En *Deploy & Run*, elegir **Injected Provider – MetaMask** (red Sepolia), indicar en el constructor la dirección admin y presionar *Deploy*.
5. Ejecutar `grantRole` con `ISSUER_ROLE` (valor: `keccak256("ISSUER_ROLE")`) para autorizar una cuenta emisora.
6. Verificar el código fuente en Etherscan (Sepolia).

**Contrato desplegado:** `0xe37D15d043d698795540aCE69206bBb7C7a86d65` ([ver en Etherscan](https://sepolia.etherscan.io/address/0xe37D15d043d698795540aCE69206bBb7C7a86d65))

## Prueba rápida

1. Con la cuenta emisora, llamar a `issueCertificate` con un hash `bytes32`, una dirección titular y un URI.
2. Revisar el evento `CertificateIssued` en los *logs* de la transacción.
3. Llamar a `verifyCertificate(hash)` desde cualquier cuenta: `valid = true`.
4. Llamar a `revokeCertificate(hash)` y volver a verificar: `valid = false`.
5. Probar con una cuenta sin rol: `issueCertificate` debe revertir.

## Interfaz web

`index.html` es una página única (HTML + JavaScript + Ethers.js v6), sin instalación ni build.

1. Abrir `index.html` en el navegador (doble clic o con una extensión tipo Live Server).
2. Pegar la dirección del contrato desplegado en Sepolia (o escribirla en `CONTRACT_ADDRESS` dentro del archivo).
3. **Verificar:** no requiere wallet. Elegir el archivo (o pegar el hash) y presionar *Verificar*.
4. **Emitir / Revocar:** conectar MetaMask (se cambia a Sepolia automáticamente) con una cuenta que tenga `ISSUER_ROLE` y completar el formulario. La emisión es la "escritura" en la blockchain que pide la guía del proyecto.

El archivo nunca se sube a ningún servidor: el hash se calcula en el navegador.

## Cálculo del hash (frontend, Ethers.js v6)

```javascript
import { keccak256 } from "ethers";

const bytes = new Uint8Array(await file.arrayBuffer());
const certHash = keccak256(bytes); // bytes32 que se envía al contrato
```

## Seguridad

- Control de acceso por roles y validaciones al inicio de cada función.
- Sin manejo de ETH ni llamadas externas: no aplica reentrancy.
- Riesgos: compromiso de la clave de un emisor (usar hardware wallet o multisig para el admin) y errores de contrato (realizar pruebas y auditoría antes de producción).
- Producción recomendada en una L2 (Base, Arbitrum u Optimism) para reducir costos.

## Stack

Solidity v0.8.20 · OpenZeppelin Contracts · Remix IDE · Sepolia · Ethers.js · MetaMask · Etherscan

## Licencia

MIT
