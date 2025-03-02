// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 

import "remix_accounts.sol";
import "../contracts/carbon.sol";

contract carbonTest is carbon {

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;

    function beforeAll() public {
        // Initiate account variables
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        acc5 = TestsAccounts.getAccount(5);
    }

    // Check owner
    function ownerTest() public {
        Assert.equal(owner, acc0, "Owner should be acc0");
    }

    // Add verifier
    function authoriseVerifiersTest() public  {
        Assert.equal(authoriseVerifiers(acc1, "Verifier1", "00038"), 1, "Verifier should be added to list");
    }

    // Add verifier fail
    /// #sender: account-1
    function authoriseVerifiersFailure() public  {
        try this.authoriseVerifiers(acc2, "Verifier1", "00038") returns (uint i){
            Assert.equal(i, 2, "Method execution did not fail");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Only owner can authorise verifiers", "Failed with unexpected reason");
        } catch Panic(uint) {
            Assert.ok(false, "Failed unexpected with error code");
        } catch (bytes memory) {
            Assert.ok(false, "Failed unexpected");
        }
    }

    // Remove verifier
    function removeVerifiersTest() public  {
        Assert.equal(removeVerifiers(acc1), 0, "Verifier should be removed from list");
    }

    // Remove verifier fail
    /// #sender: account-1
    function removeVerifiersFailure() public  {
        try this.removeVerifiers(acc2) returns (uint i){
            Assert.equal(i, 0, "Method execution did not fail");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Only owner can remove verifiers", "Failed with unexpected reason");
        } catch Panic(uint) {
            Assert.ok(false, "Failed unexpected with error code");
        } catch (bytes memory) {
            Assert.ok(false, "Failed unexpected");
        }
    }

    // Add proponent
    /// #sender: account-2
    function addProponentTest() public {
        Assert.equal(addProponent("Project1", "prop@email.com", "Sydney"), 1, "Proponent should be added");
    }

    // Submit project
    /// #sender: account-2
    function submitProjectTest() public {
        Assert.equal(submitProject("www.vera.com.Project1", 301124, 301125, "Sydney", 10000, "Transport", "00038"), 1, "Project should be submitted");
    }

    // Check project is in submitted state
    function checkStateSubmit() public {
        Project memory p = getProject(1);
        Assert.equal(uint(p.proState), uint(projectState.SUBMITTED), "Incorrect state");
    }

    // Submit project fail
    /// #sender: account-3
    function submitProjectFailure() public  {
        try this.submitProject("www.vera.com.Project1", 301124, 301125, "Sydney", 10000, "Transport", "00038") returns (uint i){
            Assert.equal(i, 2, "Method execution did not fail");
        } catch Error(string memory reason) {
            Assert.equal(reason, "User must make themselves a proponent", "Failed with unexpected reason");
        } catch Panic(uint) {
            Assert.ok(false, "Failed unexpected with error code");
        } catch (bytes memory) {
            Assert.ok(false, "Failed unexpected");
        }
    }

    // Setup for validation
    function setup() public {
        authoriseVerifiers(acc1, "Verifier1", "00038");
        authoriseVerifiers(acc2, "Verifier2", "00038");
        authoriseVerifiers(acc3, "Verifier3", "00038");
        authoriseVerifiers(acc4, "Verifier4", "00038");
        assignVerifiersValidate(1, acc1, acc2, acc3);
    }

    // Validation from first verifier
    /// #sender: account-1
    function validateVerifier1Test() public {
        Assert.equal(validateProject(1, true, "Approved"), 1, "Verifier should approve");
    }

    // /// #sender: account-4
    // function validateVerifierInvalidProjectTest() public {
    //     try this.validateProject(1, true, "Approved") returns (uint i){
    //         Assert.equal(i, 2, "Method execution did not fail");
    //     } catch Error(string memory reason) {
    //         Assert.equal(reason, "Verifier not approved for project", "Failed with unexpected reason");
    //     } catch Panic(uint) {
    //         Assert.ok(false, "Failed unexpected with error code");
    //     } catch (bytes memory) {
    //         Assert.ok(false, "Failed unexpected");
    //     }
    // }

    // Failed validation from non-verifier
    /// #sender: account-5
    function validateVerifierInvalidTest() public {
        try this.validateProject(1, true, "Approved") returns (uint i){
            Assert.equal(i, 2, "Method execution did not fail");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Verifier does not exist", "Failed with unexpected reason");
        } catch Panic(uint) {
            Assert.ok(false, "Failed unexpected with error code");
        } catch (bytes memory) {
            Assert.ok(false, "Failed unexpected");
        }
    }

    // Validation from second verifier
    /// #sender: account-2
    function validateVerifier2Test() public {
        Assert.equal(validateProject(1, true, "Approved"), 2, "Verifier should approve");
    }

    // Validation from third verifier
    /// #sender: account-3
    function validateVerifier3Test() public {
        Assert.equal(validateProject(1, true, "Approved"), 3, "Verifier should approve");
    }

    function checkStateValidation() public {
        Project memory p = getProject(1);
        Assert.equal(uint(p.proState), uint(projectState.VALIDATION), "Incorrect state");
    }

    function setup2() public {
        assignVerifiersVerify(1, acc1, acc2, acc3);
    }

    // Verification from first verifier
    /// #sender: account-1
    function verifyVerifier1Test() public {
        Assert.equal(verifyProject(1, true, "Approved"), 1, "Verifier should approve");
    }

    // /// #sender: account-4
    // function verifyVerifierInvalidProjectTest() public {
    //     try this.verifyProject(1, true, "Approved") returns (uint i){
    //         Assert.equal(i, 2, "Method execution did not fail");
    //     } catch Error(string memory reason) {
    //         Assert.equal(reason, "Verifier not approved for project", "Failed with unexpected reason");
    //     } catch Panic(uint) {
    //         Assert.ok(false, "Failed unexpected with error code");
    //     } catch (bytes memory) {
    //         Assert.ok(false, "Failed unexpected");
    //     }
    // }

    // Failed verification from non-verifier
    /// #sender: account-5
    function verifyVerifierInvalidTest() public {
        try this.verifyProject(1, true, "Approved") returns (uint i){
            Assert.equal(i, 2, "Method execution did not fail");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Verifier does not exist", "Failed with unexpected reason");
        } catch Panic(uint) {
            Assert.ok(false, "Failed unexpected with error code");
        } catch (bytes memory) {
            Assert.ok(false, "Failed unexpected");
        }
    }

    // Verification from second verifier
    /// #sender: account-2
    function verifyVerifier2Test() public {
        Assert.equal(verifyProject(1, true, "Approved"), 2, "Verifier should approve");
    }

    // Verification from third verifier
    /// #sender: account-3
    function verifyVerifier3Test() public {
        Assert.equal(verifyProject(1, true, "Approved"), 3, "Verifier should approve");
    }

    function checkStateVerification() public {
        Project memory p = getProject(1);
        Assert.equal(uint(p.proState), uint(projectState.VERIFICATION), "Incorrect state");
    }

}
    