import factoryABI from "../../../smart_contracts/abis/Factory.json";
import routerABI from "../../../smart_contracts/abis/Router.json";
import approveABI from "./ApproveABI.json";

export const FactoryABI = factoryABI.abi;
export const RouterABI = routerABI.abi;
export const ApproveABI = approveABI;

export const FACTORY_ADDRESS = factoryABI.networks["5777"].address;
export const ROUTER_ADDRESS = routerABI.networks["5777"].address;
