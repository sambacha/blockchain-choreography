pragma solidity ^0.4.24;

import "./Roles.sol";
import "./Persons.sol";

contract Choreography {

    using Roles for Roles.Role;
    using Persons for Persons.Person;

    enum States {
        READY,                 // 0 (default) | Aenderungsset kann gepushed werden
        SET_REVIEWERS,         // 1 |
        WAIT_FOR_VERIFIERS,    // 2
        WAIT_FOR_REVIEWERS,    // 3
        REJECTED               // 4
    }

    // storage variables
    States public state = States.READY;
    string public diff;
    bytes32 public id;
    Roles.Role private reviewers;
    Roles.Role private verifiers;
    Persons.Person private modelers;
    address public proposer;
    uint16 internal change_number = 0;
    uint public timestamp;

    // modifiers
    modifier isInState(States _targetState) {
        require(state == _targetState, "This action is not allowed in this state.");
        _;
    }

    modifier requireProposer(address _sender) {
        require(_sender == proposer, "Only the proposer can perform this action.");
        _;
    }

    modifier denyProposer(address _sender) {
        require(_sender != proposer, "The proposer is not allowed to perform this action.");
        _;
    }

    modifier requireVerifier(address _sender) {
        require(verifiers.has(_sender) == true, "You are not a verifier.");
        _;
    }

    modifier requireReviewer(address _sender) {
        require(reviewers.has(_sender) == true, "You are not a reviewer.");
        _;
    }

    modifier requireModeler(address _sender) {
        require(modelers.isRegistered(_sender) == true, "You are not a modeler in this diagram.");
        _;
    }

    constructor(string _username, string _email)
        public
    {
        modelers.add(msg.sender, _username, _email);
    }

    function addModeler(address _modeler, string _username, string _email)
        external
        requireModeler(msg.sender)
        returns (bool)
    {
        return modelers.add(_modeler, _username, _email);
    }

    function getModelerUsername(address _modeler)
        external
        view
        requireModeler(_modeler)
        returns (string)
    {
        return modelers.getUsername(_modeler);
    }

    function getModelerEmail(address _modeler)
        external
        view
        requireModeler(_modeler)
        returns (string)
    {
        return modelers.getEmailAddress(_modeler);
    }

    // SUBMISSION PHASE
    function proposeChange(string _diff)
        external
        isInState(States.READY)
    {
        require(bytes(_diff).length != 0, "You need to send a diff along with your proposal.");

        proposer = msg.sender;
        timestamp = block.timestamp;
        id = keccak256(abi.encodePacked(block.timestamp, change_number, proposer));
        diff = _diff;
        state = States.SET_REVIEWERS;
    }

    function addReviewer(address _reviewer)
        external
        isInState(States.SET_REVIEWERS)
        requireProposer(msg.sender)
    {
        reviewers.add(_reviewer);
    }

    // VERIFICATION PHASE
    function startVerification()
        external
        isInState(States.SET_REVIEWERS)
        requireProposer(msg.sender)
    {
        state = States.WAIT_FOR_VERIFIERS;
        // TODO Implement logic for assigning verifiers
        verifiers.add(proposer);
    }

    function approveReviewers()
        external
        isInState(States.WAIT_FOR_VERIFIERS)
        //denyProposer(msg.sender)
        requireVerifier(msg.sender)
    {
        verifiers.approve(msg.sender);
        tryToEndVerification();
    }

    function rejectReviewers()
        external
        isInState(States.WAIT_FOR_VERIFIERS)
        //denyProposer(msg.sender)
        requireVerifier(msg.sender)
    {
        verifiers.reject(msg.sender);
        tryToEndVerification();
    }

    function tryToEndVerification()
        private
        isInState(States.WAIT_FOR_VERIFIERS)
    {
        (uint openVotes, uint approveVotes, uint rejectVotes) = verifiers.getVoteDistribution();
        if (openVotes != 0) {
            return;
        }
        if (rejectVotes == 0) {
            state = States.WAIT_FOR_REVIEWERS;
        }
        // TODO: WHAT IF LIST OF REVIEWERS WAS DENIED?
    }

    // REVIEW PHASE
    function approveChange()
        external
        isInState(States.WAIT_FOR_REVIEWERS)
        requireReviewer(msg.sender)
    {
        reviewers.approve(msg.sender);
        tryToEndReview();
    }

    function rejectChange()
        external
        isInState(States.WAIT_FOR_REVIEWERS)
        requireReviewer(msg.sender)
    {
        reviewers.reject(msg.sender);
        tryToEndReview();
    }

    function tryToEndReview()
        internal
        isInState(States.WAIT_FOR_REVIEWERS)
    {
        (uint openVotes, uint approveVotes, uint rejectVotes) = reviewers.getVoteDistribution();
        if (openVotes != 0) {
            return;
        }
        if (rejectVotes == 0) {
            finalizeProposal();
        }
        // TODO: WHAT IF ANYONE REJECTED CHANGE PROPOSAL?
    }

    function finalizeProposal()
        internal
    {
        change_number++;
        verifiers.reset();
        reviewers.reset();
        state = States.READY;
    }
}
