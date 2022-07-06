import { combineReducers } from "redux";
import authReducer from "./auth";
import enrollmentReducer from "./enrollment";

export default combineReducers({
  auth: authReducer,
  enrollmentReducer,
});
