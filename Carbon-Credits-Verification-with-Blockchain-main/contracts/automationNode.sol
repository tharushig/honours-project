
// Time Scheduling a contract:
// need to go to the chainlink automation website to register an upkeep
// deploy the contract needing to be time scheduled and copy the address to upkeep
// fund it with link and then good to go


// Sending alerts to addresses:
// Using events to send alerts to addresses
// Planning to use custom logic to check the interval of the block timestamp
// Using custom logic so that we can dynamically register an upkeep for each proponent project


// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

 //link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
 //registrar: 0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

/**
 * string name = "test upkeep";
 * bytes encryptedEmail = 0x;
 * address upkeepContract = 0x...;
 * uint32 gasLimit = 500000;
 * address adminAddress = 0x....;
 * uint8 triggerType = 0;
 * bytes checkData = 0x;
 * bytes triggerConfig = 0x;
 * bytes offchainConfig = 0x;
 * uint96 amount = 1000000000000000000;
 */

interface AutomationRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

contract AutomationNode {
    LinkTokenInterface public immutable i_link;
    AutomationRegistrarInterface public immutable i_registrar;

    constructor(
        LinkTokenInterface link,
        AutomationRegistrarInterface registrar
    ) {
        i_link = link;
        i_registrar = registrar;
    }

    function registerAndPredictID() public {
        // LINK must be approved for transfer - this can be done every time or once
        // with an infinite approval
        RegistrationParams memory params = RegistrationParams({
            name: "testCode",
            encryptedEmail: "0x",
            upkeepContract: 0x81D37887AAF0013A2de277406c1C9FFc1571b421,
            gasLimit: 500000,
            adminAddress: msg.sender,
            triggerType: 1,
            checkData: "0x", // this is unused for now
            triggerConfig: "0x", // this is unused for now
            offchainConfig: "0x", // this is unused for now
            amount: 10
        });
        i_link.approve(address(i_registrar), params.amount);
        uint256 upkeepID = i_registrar.registerUpkeep(params);
        if (upkeepID != 0) {
            // DEV - Use the upkeepID however you see fit
        } else {
            revert("auto-approve disabled");
        }
    }
}




