// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/utils/Strings.sol";
import "Carbon-Credits-Verification-with-Blockchain-main/contracts/lock-contract.sol";


/*
Flow execution:
    - Deploy AlertMonitor Contract
    - sendMessage() -> message is sent to message array in alert contract
    - Deploy sender if not already deployed
    - Send >3000 to the alert contract from sender
    - getAPI()
    - Add vrf address to the vrf subscription manager
    - fund apiConsumer
    - activateOracles() -> monitor on vrf sub manager and don't continue unti fulfillment is complete
    - simulateExistingProject()
    - returnDeposits()
*/


contract AlertMonitor {
    Lock public lock;

    VRFD20 public vrf;
    APIConsumer public apiConsumer;
    VDRSend public vdr;
    // string[] message;
    

    // mapping(address => string) public messages;

    function deployLock() public {
        lock = new Lock();
        lock.deploy();
        lock.newProp();
    }

    function getAPI() public {
        vrf = lock.vrf();
        apiConsumer = lock.apiConsumer();
        vdr = lock.vdr();
    }

    function activateOracles() public {
        lock.isMonitoring(0x1047b2c86dA02c525734B932a519a38686AE7550);
        lock.addVerifier(0xCbd38adA2d31C7071e041fC8F8C1DA9Df9c76dD4, true, "testAlert");
    }

    function simulateExistingProject() public {
        lock.newProject();
    }
    
    function returnDeposits() public {
        lock.changeProjectState(lock.getProjectState(4));
    }

    receive() external payable {
        (bool success, ) = address(lock).call{value: address(this).balance}(""); 
        // require(success, "Failed to send Ether to Lock.");

    }

    function sendMessage(address recipientAddress) public {
        // messages[recipientAddress] = "Your project is scheduled to undergo its annual monitoring.";
        // message.push("Your project is scheduled to undergo its annual monitoring.");
        deployLock();
    }

}















contract Recipient {
    string public lastMessage;
    address public sender;

    // Function to receive the message
    function receiveMessage(string calldata message) external {
        lastMessage = message;
        sender = msg.sender; // Stores the sender's address
    }
}

contract SenderMoney {
    event LogMessage(string, address);
    function sendEther(address payable receiverAddress) public payable {
        // Sending Ether to the receiver contract
        //Need to do the same for verra but not sure how
        (bool success, ) = receiverAddress.call{value: msg.value}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {
        testReturn();
    }

    function testReturn () public {
        emit LogMessage("Sender received money back", address(this));
    }
}