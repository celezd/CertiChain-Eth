// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title CertificateRegistry
/// @notice Registro público de certificados académicos. Solo se guarda el hash
///         del documento (nunca datos personales). Los emisores autorizados
///         registran y pueden revocar; cualquiera puede verificar.
contract CertificateRegistry is AccessControl {
    // Rol de las instituciones autorizadas a emitir certificados
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // issuer (20 bytes) + issuedAt (8) + revoked (1) comparten un slot de storage
    struct Certificate {
        address issuer;
        uint64 issuedAt;
        bool revoked;
        address recipient;
    }

    // hash del certificado => datos del certificado
    mapping(bytes32 => Certificate) private _certificates;

    // El metadataURI (ej. ipfs://...) viaja solo en el evento: los logs son mucho más baratos que storage
    event CertificateIssued(
        bytes32 indexed certHash,
        address indexed issuer,
        address indexed recipient,
        string metadataURI
    );
    event CertificateRevoked(bytes32 indexed certHash, address indexed revokedBy);

    /// @param admin Cuenta administradora (recomendado: multisig o hardware wallet)
    constructor(address admin) {
        require(admin != address(0), "Admin invalido");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Registra un certificado. Solo cuentas con ISSUER_ROLE.
    function issueCertificate(
        bytes32 certHash,
        address recipient,
        string calldata metadataURI
    ) external onlyRole(ISSUER_ROLE) {
        // Validaciones al inicio: fallar temprano ahorra gas
        require(certHash != bytes32(0), "Hash invalido");
        require(recipient != address(0), "Destinatario invalido");
        require(_certificates[certHash].issuedAt == 0, "Certificado ya registrado");

        _certificates[certHash] = Certificate({
            issuer: msg.sender,
            issuedAt: uint64(block.timestamp),
            revoked: false,
            recipient: recipient
        });

        emit CertificateIssued(certHash, msg.sender, recipient, metadataURI);
    }

    /// @notice Revoca un certificado. Solo el emisor original o el administrador.
    function revokeCertificate(bytes32 certHash) external {
        Certificate storage cert = _certificates[certHash];
        require(cert.issuedAt != 0, "Certificado inexistente");
        require(!cert.revoked, "Ya revocado");
        require(
            msg.sender == cert.issuer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "No autorizado"
        );

        cert.revoked = true;
        emit CertificateRevoked(certHash, msg.sender);
    }

    /// @notice Verifica un certificado. Gratuita al llamarse desde fuera de la red.
    /// @return exists true si el hash fue registrado
    /// @return valid true si existe y no fue revocado
    function verifyCertificate(bytes32 certHash)
        external
        view
        returns (
            bool exists,
            bool valid,
            address issuer,
            address recipient,
            uint64 issuedAt
        )
    {
        Certificate memory cert = _certificates[certHash];
        exists = cert.issuedAt != 0;
        valid = exists && !cert.revoked;
        issuer = cert.issuer;
        recipient = cert.recipient;
        issuedAt = cert.issuedAt;
    }
}
