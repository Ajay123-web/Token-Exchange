import { Schema, model, models } from "mongoose";

const tokenSchema = new Schema({
  address: {
    type: String,
    unique: true,
  },

  pools: [
    {
      type: String,
    },
  ],
});

const Token = models.Token || model("Token", tokenSchema);
export default Token;
