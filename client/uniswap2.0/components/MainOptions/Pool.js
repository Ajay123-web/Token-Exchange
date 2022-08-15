import Image from "next/image";
import { RiSettings3Fill } from "react-icons/ri";
import { AiOutlineDown } from "react-icons/ai";
import { useState, useContext } from "react";
import { Web3Context } from "../../context/StateProvider";
import { useRouter } from "next/router";
//import TransactionLoader from "./TransactionLoader";

//Modal.setAppElement("#__next");

const style = {
  wrapper: `w-screen flex justify-center items-center mb-[100px] overflow-hidden`,
  content: `bg-[#191B1F] w-[40rem] rounded-2xl p-4`,
  formHeader: `px-2 flex items-center justify-between font-semibold text-xl`,
  transferPropContainer: `bg-[#20242A] my-2 rounded-2xl p-3 text-2xl  border border-[#20242A] hover:border-[#41444F] flex justify-between items-center`,
  transferPropInput: `bg-transparent placeholder:text-[#B2B9D2] outline-none mb-6 w-full text-2xl`,
  confirmButton: `bg-[#2172E5] my-2 rounded-2xl py-6 px-8 text-xl font-semibold flex items-center justify-center cursor-pointer border border-[#2172E5] hover:border-[#234169]`,
};

const customStyles = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    transform: "translate(-50%, -50%)",
    backgroundColor: "#0a0b0d",
    padding: 0,
    border: "none",
  },
  overlay: {
    backgroundColor: "rgba(10, 11, 13, 0.75)",
  },
};

const Pool = () => {
  const { addHandleChange, addLiquidity } = useContext(Web3Context);

  const [tx, setTx] = useState(false);

  const handleSubmit = async () => {
    try {
      setTx(true);
      await addLiquidity();
      setTx(false);
    } catch {
      setTx(false);
      alert("Some error occured....");
    }
  };

  return (
    <div className={style.wrapper}>
      <div className={style.content}>
        <div className={style.formHeader}>
          <div>Pool</div>
          <div>
            <RiSettings3Fill />
          </div>
        </div>
        <div className={style.transferPropContainer}>
          <input
            type="text"
            className={style.transferPropInput}
            placeholder="Paste contract address"
            onChange={(e) => addHandleChange(e, "tokenA")}
          />
        </div>
        <div className={style.transferPropContainer}>
          <input
            type="number"
            className={style.transferPropInput}
            placeholder="0.0"
            onChange={(e) => addHandleChange(e, "amountA")}
          />
        </div>
        <div className={style.transferPropContainer}>
          <input
            type="text"
            className={style.transferPropInput}
            placeholder="Paste contract address"
            onChange={(e) => addHandleChange(e, "tokenB")}
          />
        </div>
        <div className={style.transferPropContainer}>
          <input
            type="number"
            className={style.transferPropInput}
            placeholder="0.0"
            onChange={(e) => addHandleChange(e, "amountB")}
          />
        </div>
        <div className={style.transferPropContainer}>
          <input
            type="text"
            className={style.transferPropInput}
            placeholder="LP token receipent address"
            onChange={(e) => addHandleChange(e, "to")}
          />
        </div>
        <div onClick={(e) => handleSubmit(e)} className={style.confirmButton}>
          {tx ? "Processing..." : "ADD LIQUIDITY"}
        </div>
      </div>

      {/* <Modal isOpen={!!router.query.loading} style={customStyles}>
        <TransactionLoader />
      </Modal> */}
    </div>
  );
};

export default Pool;
