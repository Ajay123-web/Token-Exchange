import React from "react";
import { useEffect, useState } from "react";
import Web3 from "web3";
import axios from "../utils/Axios";
import {
  FACTORY_ADDRESS,
  ROUTER_ADDRESS,
  FactoryABI,
  RouterABI,
  ApproveABI,
} from "../libs/constants";

export const Web3Context = React.createContext();

let web3;

const fetchPools = async () => {
  try {
    const pools = await axios({
      method: "get",
      url: "/GetAllPools",
    });
    return pools;
  } catch (err) {
    console.log("ERR!");
  }
};

const BFS = (tree, rootNode, searchNode) => {
  let parent = {};
  for (var key in tree) {
    parent[key] = "0x";
  }
  parent[rootNode] = "0x";
  parent[searchNode] = "0x";
  let queue = [];
  queue.push(rootNode);
  while (queue.length > 0) {
    let currNode = queue[0];
    if (tree[currNode] !== undefined) {
      let neighbours = tree[currNode];
      if (neighbours) {
        for (let i = 0; i < neighbours.length; i++) {
          if (neighbours[i] !== rootNode && parent[neighbours[i]] == "0x") {
            queue.push(neighbours[i]);
            parent[neighbours[i]] = currNode;
          }
        }
      }
    }

    queue.shift();
  }
  //console.log(parent);
  let path = [];
  let start = searchNode;
  while (parent[start] !== "0x") {
    path.push(start);
    start = parent[start];
  }

  if (start != rootNode) {
    return []; //cant swap tokens bcz no pool exists
  }

  path.push(rootNode);
  path.reverse();
  return path;
};

export const Web3Provider = ({ children }) => {
  const [account, setAccount] = useState("");
  const [chain, setChain] = useState("");
  const [headerOption, setHeaderOption] = useState(1);
  const [swapFormData, setSwapFormData] = useState({
    tokenA: "",
    tokenB: "",
    amountIn: 0,
  });

  const [addFormData, setAddFormData] = useState({
    tokenA: "",
    tokenB: "",
    amountA: 0,
    amountB: 0,
    to: "",
  });

  const swapHandleChange = (e, name) => {
    setSwapFormData((prevState) => ({ ...prevState, [name]: e.target.value }));
  };

  const addHandleChange = (e, name) => {
    setAddFormData((prevState) => ({ ...prevState, [name]: e.target.value }));
  };

  const getPath = async () => {
    try {
      const pools = await fetchPools();
      const arrayObj = pools.data;
      let tree = {};
      for (let i = 0; i < arrayObj.length; i++) {
        tree[arrayObj[i].address] = [];
        for (let j = 0; j < arrayObj[i].pools.length; j++) {
          tree[arrayObj[i].address].push(arrayObj[i].pools[j]);
        }
      }

      return BFS(tree, swapFormData.tokenA, swapFormData.tokenB);
    } catch (err) {}
  };

  const findAmount = async () => {
    //console.log(ROUTER_ADDRESS);
    //console.log(FACTORY_ADDRESS);
    try {
      const path = await getPath();
      console.log("PATH", path);
      if (!path) throw -1;
      const contract = new web3.eth.Contract(RouterABI, ROUTER_ADDRESS);
      const amountOut = await contract.methods
        .getOutAmount(amountIn, path)
        .call();
      return amountOut;
    } catch (err) {
      //console.log(err);
    }
  };

  const addLiquidity = async () => {
    /*
      -> transaction through metamask
      -> tokenA , tokenB , amountA , amountB
      -> Approve Router address to transfer token to pool (call on Token address)
      -> Call addLiquidity on Router Contract
    */
    console.log(addFormData);
    try {
      let contract = new web3.eth.Contract(ApproveABI, addFormData.tokenA);
      await contract.methods
        .approve(ROUTER_ADDRESS, addFormData.amountA)
        .send({ from: account });
      contract = new web3.eth.Contract(ApproveABI, addFormData.tokenB);
      await contract.methods
        .approve(ROUTER_ADDRESS, addFormData.amountB)
        .send({ from: account });

      contract = new web3.eth.Contract(RouterABI, ROUTER_ADDRESS);
      await contract.methods
        .addLiquidity(
          addFormData.tokenA,
          addFormData.tokenB,
          addFormData.amountA,
          addFormData.amountB,
          0,
          0,
          addFormData.to,
          1000000000000000000n
        )
        .send({ from: account });
    } catch (err) {
      console.log(err);
    }
  };

  const swap = async () => {
    try {
      const path = await getPath();
      const contract = new web3.eth.Contract(RouterABI, ROUTER_ADDRESS);
      await contract.methods
        .swapExactTokensForTokens(
          swapFormData.amountIn,
          0,
          path,
          account,
          1000000000000000000n
        )
        .send({ from: account });
    } catch (err) {
      console.log(err);
    }
  };

  useEffect(() => {
    window.web3 = new Web3(window.ethereum);
    web3 = window.web3;
  }, []);

  return (
    <Web3Context.Provider
      value={{
        account,
        setAccount,
        chain,
        setChain,
        swapFormData,
        setSwapFormData,
        swapHandleChange,
        findAmount,
        headerOption,
        setHeaderOption,
        addFormData,
        setAddFormData,
        addHandleChange,
        addLiquidity,
        swap,
      }}
    >
      {children}
    </Web3Context.Provider>
  );
};
