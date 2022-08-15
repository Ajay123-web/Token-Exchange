import connect from "../../utils/connectDB";
import Token from "../../models/Token";

const getPools = async (req, res) => {
  try {
    await connect();
    const pools = await Token.find();
    res.status(200).json(pools);
  } catch (err) {
    res.status(404).json({ message: err.message });
  }
};

export default getPools;
