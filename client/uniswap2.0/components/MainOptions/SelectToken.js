import React, { useContext } from "react";
import { ImCross } from "react-icons/im";
import { Web3Context } from "../../context/StateProvider";
import Image from "next/image";
import ethLogo from "../../assets/eth.png";
import wbtcLogo from "../../assets/wbtc.png";
import daiLogo from "../../assets/dai.png";
import aaveLogo from "../../assets/aave.png";
import usdtLogo from "../../assets/usdt.png";
import balLogo from "../../assets/balancer.png";

function SelectToken({ token, openSelectToken }) {
  const { swapHandleChange } = useContext(Web3Context);
  const onClose = () => {
    openSelectToken(false);
  };
  return (
    <div className="modalBackground">
      <div className="modalContainer rounded-2xl p-4">
        <div className="px-2 flex items-center justify-between font-semibold text-xl">
          <div className>Select</div>
          <button onClick={onClose}>
            <ImCross />
          </button>
        </div>
        <div className="bg-[#20242A] my-3 mt-[30px] rounded-2xl p-2 text-xl  border border-[#20242A] hover:border-[#41444F]  flex justify-between items-center">
          <input
            type="text"
            placeholder="Select name or paste address"
            className="flex items-center bg-transparent placeholder:text-[#B2B9D2] outline-none mb-6 w-full text-xl"
            onChange={(e) => swapHandleChange(e, token)}
          />
        </div>
        <div className="flex my-[25px]">
          <div className="flex border-[1px] border-gray-800 mx-[10px] p-3 w-[100px] rounded-lg">
            <Image src={ethLogo} alt="" height={20} width={20} />
            <p className="ml-[15px]">ETH</p>
          </div>
          <div className="flex border-[1px] border-gray-800 mx-[10px] p-3 w-[100px] rounded-lg">
            <Image src={wbtcLogo} alt="" height={20} width={20} />
            <p className="ml-[15px]">WBTC</p>
          </div>
          <div className="flex border-[1px] border-gray-800 mx-[10px] p-3 w-[100px] rounded-lg">
            <Image src={daiLogo} alt="" height={20} width={20} />
            <p className="ml-[15px]">DAI</p>
          </div>
        </div>
        <div className="flex">
          <div className="flex border-[1px] border-gray-800 mx-[10px] p-3 w-[100px] rounded-lg">
            <Image src={aaveLogo} alt="" height={20} width={20} />
            <p className="ml-[15px]">AAVE</p>
          </div>
          <div className="flex border-[1px] border-gray-800 mx-[10px] p-3 w-[100px] rounded-lg">
            <Image src={usdtLogo} alt="" height={20} width={20} />
            <p className="ml-[15px]">USDT</p>
          </div>
          <div className="flex border-[1px] border-gray-800 mx-[10px] p-3 w-[100px] rounded-lg">
            <Image src={balLogo} alt="" height={20} width={20} />
            <p className="ml-[15px]">BAL</p>
          </div>
        </div>
      </div>{" "}
    </div>
  );
}

export default SelectToken;
