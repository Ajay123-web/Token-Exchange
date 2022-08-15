import Image from "next/image";
import { RiSettings3Fill } from "react-icons/ri";
import { AiOutlineDown } from "react-icons/ai";
import ethLogo from "../../assets/eth.png";
import { useState, useContext } from "react";
import { Web3Context } from "../../context/StateProvider";
import SelectToken from "./SelectToken";
import { useRouter } from "next/router";
//import TransactionLoader from "./TransactionLoader";

//Modal.setAppElement("#__next");

const style = {
  wrapper: `w-screen flex justify-center items-center mb-[100px]`,
  content: `bg-[#191B1F] w-[40rem] rounded-2xl p-4`,
  formHeader: `px-2 flex items-center justify-between font-semibold text-xl`,
  transferPropContainer: `bg-[#20242A] my-3 rounded-2xl p-6 text-3xl  border border-[#20242A] hover:border-[#41444F]  flex justify-between items-center`,
  transferPropInput: `bg-transparent placeholder:text-[#B2B9D2] outline-none mb-6 w-full text-2xl`,
  currencySelector: `flex w-1/4`,
  currencySelectorContent: `w-full h-min flex justify-between items-center bg-[#2D2F36] hover:bg-[#41444F] rounded-2xl text-xl font-medium cursor-pointer p-2 mt-[-0.2rem]`,
  currencySelectorIcon: `flex items-center`,
  currencySelectorTicker: `mx-2`,
  currencySelectorArrow: `text-lg`,
  confirmButton: `bg-[#2172E5] my-2 rounded-2xl py-6 px-8 text-xl font-semibold flex items-center justify-center cursor-pointer border border-[#2172E5] hover:border-[#234169]`,
};

const Swap = () => {
  const { swapHandleChange, findAmount, swap } = useContext(Web3Context);

  const [selectToken, openSelectToken] = useState(false);
  const [Token, setToken] = useState("");
  const [estAmount, setEstAmount] = useState(0.0);
  const [est, setEst] = useState(false);
  const [tx, setTx] = useState(false);

  const handleSubmit = async () => {
    setTx(true);
    try {
      await swap();
      setTx(false);
    } catch (err) {
      setTx(false);
      alert("Something went wrong");
    }
  };

  const FindAmount = async () => {
    setEst(true);
    try {
      const amountOut = await findAmount();
      setEst(false);
      setEstAmount(amountOut);
    } catch (err) {
      setEst(false);
      if (err == "-1") {
        alert("No Pool exist");
      } else {
        console.log(err);
        alert("Some error occured");
      }
    }
  };

  return (
    <div className={style.wrapper}>
      <div className={style.content}>
        <div className={style.formHeader}>
          <div>Swap</div>
          <div>
            <RiSettings3Fill />
          </div>
        </div>
        <div className={style.transferPropContainer}>
          <input
            type="number"
            className={style.transferPropInput}
            placeholder="0.0"
            onChange={(e) => swapHandleChange(e, "amountIn")}
          />
          <div className={style.currencySelector}>
            <div className={style.currencySelectorContent}>
              <div
                onClick={() => {
                  openSelectToken(true);
                  setToken("tokenA");
                }}
                className={style.currencySelectorTicker}
              >
                Select
              </div>
              <AiOutlineDown className={style.currencySelectorArrow} />
            </div>
          </div>
        </div>
        <div className={style.transferPropContainer}>
          <div className={style.transferPropInput}>
            <button
              onClick={FindAmount}
              className="bg-[#2D2F36] hover:bg-[#41444F] p-3 rounded-md cursor-pointer"
            >
              {est ? "Calculating..." : "Est. Amount :"} {estAmount}
            </button>
          </div>
          <div className={style.currencySelector}>
            <div className={style.currencySelectorContent}>
              <div
                onClick={() => {
                  openSelectToken(true);
                  setToken("tokenB");
                }}
                className={style.currencySelectorTicker}
              >
                Select
              </div>
              <AiOutlineDown className={style.currencySelectorArrow} />
            </div>
          </div>
        </div>
        <div onClick={(e) => handleSubmit(e)} className={style.confirmButton}>
          {tx ? "Processing..." : "SWAP"}
        </div>
      </div>
      {selectToken ? (
        <SelectToken token={Token} openSelectToken={openSelectToken} />
      ) : (
        <></>
      )}
    </div>
  );
};

export default Swap;
