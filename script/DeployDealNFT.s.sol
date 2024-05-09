// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../src/DealNFT.sol";

contract DeployDealNFT is Script {
    function run() external {
        bytes32 salt = 0x6551655165516551655165516551655165516551655165516551655165516551;
        address factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

        address registry = 0x000000006551c19487814612e58FE06813775758;
        address implementation = 0xbc9c43812ebD8066117Ae6e9Ad617bB378BFA8A1;
        address sponsor = 0x7Adc86401f246B87177CEbBEC189dE075b75Af3A;
        string memory name = "SurgeDealTEST";
        string memory symbol = "SRGTEST";
        string memory baseURI = "https://surgetokens.netlify.app";

        address deal = Create2.computeAddress(
            salt,
            keccak256(
                abi.encodePacked(
                    type(DealNFT).creationCode,
                    abi.encode(
                        registry,
                        implementation,
                        sponsor,
                        name,
                        symbol,
                        baseURI
                    )
                )
            ),
            factory
        );

        // Deploy Deal
        if (deal.code.length == 0) {
            vm.startBroadcast();
            new DealNFT{salt: salt}(
                registry,
                implementation,
                sponsor,
                name,
                symbol,
                baseURI
            );
            vm.stopBroadcast();

            console.log("DealNFT:", deal, "(deployed)");
        } else {
            console.log("DealNFT:", deal, "(exists)");
        }

        console.log("\nVerification Commands:\n");
        console.log(
            "DealNFT: forge verify-contract --num-of-optimizations 200 --chain-id",
            block.chainid,
            deal,
            string.concat(
                "src/DealNFT.sol:DealNFT --constructor-args $(cast abi-encode \"constructor(address,address,address,string,string,string)\" ",
                Strings.toHexString(registry),
                " ",
                Strings.toHexString(implementation),
                " ",
                Strings.toHexString(sponsor),
                " ",
                name,
                " ",
                symbol,
                " ",
                baseURI,
                ")\n"
            )
        );
    }
}