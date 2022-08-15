import connect from "../../utils/connectDB";
import Token from "../../models/Token";

const Create = async (req, res) => {
  try {
    const { tokenA, tokenB } = req.body;
    await connect();
    const options = {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true,
    };

    const TA = await Token.findOneAndUpdate(
      { address: tokenA },
      { $addToSet: { pools: tokenB } },
      options
    );
    const TB = await Token.findOneAndUpdate(
      { address: tokenB },
      { $addToSet: { pools: tokenA } },
      options
    );

    // await Token.update({ _id: TA._id }, { $push: { pools: tokenB } });
    // let TB = await Token.find({ address: tokenB });
    // if (TB) {
    //   await Token.create({ address: tokenB });
    // }
    // await Token.update({ _id: TB._id }, { $push: { pools: tokenA } });
    res.status(201).json({ message: "Pool updated successfully" });
  } catch (err) {
    res.status(404).json({ message: err.message });
  }
};

export default Create;
//password uniswap
