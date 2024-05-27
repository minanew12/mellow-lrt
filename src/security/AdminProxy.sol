// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/security/IAdminProxy.sol";

contract AdminProxy is IAdminProxy {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IAdminProxy
    ITransparentUpgradeableProxy public immutable proxy;
    /// @inheritdoc IAdminProxy
    address public proposer;
    address public stagedProposer;
    /// @inheritdoc IAdminProxy
    address public acceptor;
    /// @inheritdoc IAdminProxy
    address public emergencyOperator;
    /// @inheritdoc IAdminProxy
    uint256 public latestAcceptedNonce;

    Proposal private _baseImplementation;
    Proposal private _proposedBaseImplementation;
    Proposal[] private _proposals;

    constructor(
        address proxy_,
        address proposer_,
        address acceptor_,
        address baseImplementation_
    ) {
        proxy = ITransparentUpgradeableProxy(proxy_);
        proposer = proposer_;
        acceptor = acceptor_;
        _baseImplementation = Proposal({
            implementation: baseImplementation_,
            callData: new bytes(0)
        });
    }

    modifier requireProposerOrAcceptor() {
        if (msg.sender != proposer || msg.sender == acceptor)
            revert Forbidden();
        _;
    }

    modifier onlyAcceptor() {
        if (msg.sender != acceptor) revert Forbidden();
        _;
    }

    modifier onlyEmergencyOperator() {
        if (msg.sender != emergencyOperator) revert Forbidden();
        _;
    }

    /// @inheritdoc IAdminProxy
    function baseImplementation() external view returns (Proposal memory) {
        return _baseImplementation;
    }

    /// @inheritdoc IAdminProxy
    function proposedBaseImplementation()
        external
        view
        returns (Proposal memory)
    {
        return _proposedBaseImplementation;
    }

    /// @inheritdoc IAdminProxy
    function proposalAt(uint256 index) external view returns (Proposal memory) {
        return _proposals[index];
    }

    /// @inheritdoc IAdminProxy
    function proposalsCount() external view returns (uint256) {
        return _proposals.length;
    }

    /// @inheritdoc IAdminProxy
    function upgradeEmergencyOperator(
        address newEmergencyOperator
    ) external onlyAcceptor {
        emergencyOperator = newEmergencyOperator;
    }

    /// @inheritdoc IAdminProxy
    function upgradeProposer(address newProposer) external onlyAcceptor {
        proposer = newProposer;
    }

    /// @inheritdoc IAdminProxy
    function upgradeAcceptor(address newAcceptor) external onlyAcceptor {
        acceptor = newAcceptor;
    }

    /// @inheritdoc IAdminProxy
    function proposeBaseImplementation(
        address implementation,
        bytes calldata callData
    ) external requireProposerOrAcceptor {
        _proposedBaseImplementation = Proposal({
            implementation: implementation,
            callData: callData
        });
    }

    /// @inheritdoc IAdminProxy
    function propose(
        address implementation,
        bytes calldata callData
    ) external requireProposerOrAcceptor {
        _proposals.push(
            Proposal({implementation: implementation, callData: callData})
        );
    }

    /// @inheritdoc IAdminProxy
    function acceptBaseImplementation() external onlyAcceptor {
        _baseImplementation = _proposedBaseImplementation;
    }

    /// @inheritdoc IAdminProxy
    function acceptProposal(uint256 index) external onlyAcceptor {
        if (
            index == 0 ||
            index <= latestAcceptedNonce ||
            _proposals.length < index
        ) revert Forbidden();
        Proposal memory proposal = _proposals[index - 1];
        proxy.upgradeToAndCall(proposal.implementation, proposal.callData);
        latestAcceptedNonce = index;
    }

    /// @inheritdoc IAdminProxy
    function rejectAllProposals() external onlyAcceptor {
        latestAcceptedNonce = _proposals.length;
    }

    /// @inheritdoc IAdminProxy
    function resetToBaseImplementation() external onlyEmergencyOperator {
        proxy.upgradeToAndCall(
            _baseImplementation.implementation,
            _baseImplementation.callData
        );
        emergencyOperator = address(0);
    }
}
