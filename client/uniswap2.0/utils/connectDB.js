import mongoose from "mongoose";

const connect = async () => {
  // console.log(process.env.MONGO_URI);
  await mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useFindAndModify: false,
  });
};

export default connect;
