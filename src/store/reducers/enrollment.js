// import {
//   REGISTER_SUCCESS,
//   REGISTER_FAIL,
//   LOGIN_SUCCESS,
//   LOGIN_FAIL,
//   LOGOUT_SUCCESS,
//   LOGOUT_FAIL,
//   LOAD_USER_SUCCESS,
//   LOAD_USER_FAIL,
//   AUTHENTICATED_SUCCESS,
//   AUTHENTICATED_FAIL,
//   REFRESH_SUCCESS,
//   REFRESH_FAIL,
//   SET_AUTH_LOADING,
//   REMOVE_AUTH_LOADING,
//   SSO_FAIL,
//   SSO_SUCCESS,
//   SSO_INPROGRESS,
//   SELECT_ROLE,
// } from "../constants/authConstant";

// const initialState = {
//   user: JSON.parse(sessionStorage.getItem("user")) || {
//     firstName: "",
//     role: "",
//     roleId: null,
//     userId: null,
//     userName: "",
//     currentRole: "",
//   },
//   // user: { roles: [], name: "" },
//   isAuthenticated: !!sessionStorage.getItem("token"),
//   // isAuthenticated: false,
//   loading: false,
//   roleSelection: true,
// };

const enrollmentReducer = (state = {}, action) => {
  const { type, payload } = action;

  switch (type) {
    case "CLINICAL_INFO":
      return {
        ...state,
        payload,
      };
    default:
      return state;
  }
};

export default enrollmentReducer;
