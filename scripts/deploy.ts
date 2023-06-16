import * as dotenv from "dotenv";
import {ethers, run} from "hardhat";
import {Contract, ContractFactory} from "ethers";

dotenv.config();

const deployAndVerify = async (
    name: string,
    params: any[],
    canVerify: boolean = true,
    path?: string | undefined,
): Promise<Contract> => {
    const Factory: ContractFactory = await ethers.getContractFactory(name);
    const instance: Contract = await Factory.deploy(...params);
    await instance.deployed();

    if (canVerify)
        await run(`verify:verify`, {
            contract: path,
            address: instance.address,
            constructorArguments: params,
        });

    console.log(`${name} deployed at: ${instance.address}`);

    return instance;
};

async function main() {
    const multiTransfer = await deployAndVerify(
        "MultiTransfer",
        [],
        true,
        "contracts/MultiTransfer.sol:MultiTransfer"
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
