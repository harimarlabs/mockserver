import { toast } from "react-toastify";
import axios from "axios";

import {
  REGISTER_SUCCESS,
  REGISTER_FAIL,
  //   RESET_REGISTER_SUCCESS,
  LOGIN_SUCCESS,
  LOGIN_FAIL,
  LOGOUT_SUCCESS,
  LOGOUT_FAIL,
  LOAD_USER_SUCCESS,
  LOAD_USER_FAIL,
  AUTHENTICATED_SUCCESS,
  AUTHENTICATED_FAIL,
  REFRESH_SUCCESS,
  REFRESH_FAIL,
  SET_AUTH_LOADING,
  REMOVE_AUTH_LOADING,
} from "../constants/authConstant";

import API from "../../util/apiService";

export const loadUser = () => async (dispatch) => {
  try {
    const { data } = await API.get("/authentication/api/v1.0/auth/user");
    dispatch({
      type: LOAD_USER_SUCCESS,
      payload: data,
    });
  } catch (err) {
    dispatch({
      type: LOAD_USER_FAIL,
    });
  }
};

// export const check_auth_status = () => async (dispatch) => {
//   try {
//     const res = await fetch("/api/account/verify", {
//       method: "GET",
//       headers: {
//         Accept: "application/json",
//       },
//     });

//     if (res.status === 200) {
//       dispatch({
//         type: AUTHENTICATED_SUCCESS,
//       });
//       dispatch(load_user());
//     } else {
//       dispatch({
//         type: AUTHENTICATED_FAIL,
//       });
//     }
//   } catch (err) {
//     dispatch({
//       type: AUTHENTICATED_FAIL,
//     });
//   }
// };

// export const request_refresh = () => async (dispatch) => {
//   try {
//     const res = await fetch("/api/account/refresh", {
//       method: "GET",
//       headers: {
//         Accept: "application/json",
//       },
//     });

//     if (res.status === 200) {
//       dispatch({
//         type: REFRESH_SUCCESS,
//       });
//       dispatch(check_auth_status());
//     } else {
//       dispatch({
//         type: REFRESH_FAIL,
//       });
//     }
//   } catch (err) {
//     dispatch({
//       type: REFRESH_FAIL,
//     });
//   }
// };

export const registerUser = (userData, route) => async (dispatch) => {
  try {
    dispatch({ type: SET_AUTH_LOADING });

    // const { data } = await API.post("/auth/signup", userData);
    const { data } = await API.post("/authentication/api/v1.0/auth/signup", userData);

    toast.success("User Created Successfully");

    dispatch({
      type: REGISTER_SUCCESS,
      payload: data,
    });

    route("/login");
  } catch (error) {
    toast.error(`${error.response.data}`);

    dispatch({
      type: REGISTER_FAIL,
      payload: error.response.data,
    });
  }

  dispatch({
    type: REMOVE_AUTH_LOADING,
  });
};

export const loginUser = (userData, route) => async (dispatch) => {
  try {
    dispatch({ type: SET_AUTH_LOADING });

    const { data } = await API.post("/authentication/api/v1.0/auth/signin", userData);
    // const { data } = await axios.post(
    //   "http://cms-loadbalancer-test-3-200805129.ap-south-1.elb.amazonaws.com:9003/api/v1.0/auth/signin",
    //   userData,
    // );

    // const data = {
    //   accessToken:
    //     "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhZG1pbiIsImlhdCI6MTY1NDA5NTI4OCwiZXhwIjoxNjU0NzAwMDg4fQ.LmYkKVgjOAhjimwAsRbLzkh8NMKKtcDs36HxJd1nUnlnNvd02RXAKDRCZj3uat_YFrxIrwD9fxalyv5t0QDUcw",
    //   tokenType: "Bearer",
    //   firstName: "Admin FName",
    //   userId: 1,
    //   userName: "admin",
    //   roleId: 1,
    //   role: "ROLE_CARE_MANAGER,ROLE_ADMIN",
    // };

    // data.role

    if (data.role !== "ROLE_CARE_MANAGER") {
      data.role = `${data.role},ROLE_CARE_MANAGER`;
    }

    // console.log("role", data.role);

    sessionStorage.setItem("token", JSON.stringify(data.accessToken));
    sessionStorage.setItem("user", JSON.stringify(data));
    toast.success("User Login Successfully");

    dispatch({
      type: LOGIN_SUCCESS,
      payload: data,
    });
    // dispatch(loadUser());

    route("/dashboard");
  } catch (error) {
    console.error(error);

    // toast.error(`${error.response.data}`);
    // console.error(error);
    // dispatch({
    //   type: LOGIN_FAIL,
    //   // payload: error.response.data,
    // });
  }

  dispatch({
    type: REMOVE_AUTH_LOADING,
  });
};

// export const register =
//   (first_name, last_name, username, password, re_password) =>
//   async (dispatch) => {
//     const body = JSON.stringify({
//       first_name,
//       last_name,
//       username,
//       password,
//       re_password,
//     });

//     dispatch({
//       type: SET_AUTH_LOADING,
//     });

//     try {
//       const res = await fetch("/api/account/register", {
//         method: "POST",
//         headers: {
//           Accept: "application/json",
//           "Content-Type": "application/json",
//         },
//         body,
//       });

//       if (res.status === 201) {
//         dispatch({
//           type: REGISTER_SUCCESS,
//         });
//       } else {
//         dispatch({
//           type: REGISTER_FAIL,
//         });
//       }
//     } catch (err) {
//       dispatch({
//         type: REGISTER_FAIL,
//       });
//     }

//     dispatch({
//       type: REMOVE_AUTH_LOADING,
//     });
//   };

// export const reset_register_success = () => (dispatch) => {
//   dispatch({
//     type: RESET_REGISTER_SUCCESS,
//   });
// };

// export const login = (username, password) => async (dispatch) => {
//   const body = JSON.stringify({
//     username,
//     password,
//   });

//   dispatch({
//     type: SET_AUTH_LOADING,
//   });

//   try {
//     const res = await fetch("/api/account/login", {
//       method: "POST",
//       headers: {
//         Accept: "application/json",
//         "Content-Type": "application/json",
//       },
//       body,
//     });

//     if (res.status === 200) {
//       dispatch({
//         type: LOGIN_SUCCESS,
//       });
//       dispatch(load_user());
//     } else {
//       dispatch({
//         type: LOGIN_FAIL,
//       });
//     }
//   } catch (err) {
//     dispatch({
//       type: LOGIN_FAIL,
//     });
//   }

//   dispatch({
//     type: REMOVE_AUTH_LOADING,
//   });
// };

export const logoutUser = (route) => async (dispatch) => {
  try {
    // const { data } = await API.post("/auth/logout", {});
    sessionStorage.removeItem("token");
    sessionStorage.clear();
    toast.success("User Logout Successfully");
    route("/login");
    dispatch({
      type: LOGOUT_SUCCESS,
    });
  } catch (error) {
    toast.error(`${error.response.data}`);
    dispatch({
      type: LOGOUT_FAIL,
    });
  }
};

// export default { registerUser };
