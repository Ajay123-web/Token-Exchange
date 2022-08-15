import React, { useContext } from "react";
import { Web3Context } from "../context/StateProvider";
import Swap from "./MainOptions/Swap";
import Pool from "./MainOptions/Pool";

function Main() {
  const { headerOption } = useContext(Web3Context);
  return (
    <div className="overflow-hidden">
      {headerOption == 1 ? <Swap /> : <Pool />}
    </div>
  );
}

export default Main;
