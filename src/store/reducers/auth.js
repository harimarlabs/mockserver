import {
  REGISTER_SUCCESS,
  REGISTER_FAIL,
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
  SSO_FAIL,
  SSO_SUCCESS,
  SSO_INPROGRESS,
  SELECT_ROLE,
} from "../constants/authConstant";

const initialState = {
  user: JSON.parse(sessionStorage.getItem("user")) || {
    firstName: "",
    role: "",
    roleId: null,
    userId: null,
    userName: "",
    currentRole: "",
  },
  // user: { roles: [], name: "" },
  isAuthenticated: !!sessionStorage.getItem("token"),
  // isAuthenticated: false,
  loading: false,
  roleSelection: true,
};

const authReducer = (state = initialState, action) => {
  const { type, payload } = action;

  switch (type) {
    case REGISTER_SUCCESS:
      return {
        ...state,
      };
    case REGISTER_FAIL:
      return {
        ...state,
      };

    case LOGIN_SUCCESS:
      return {
        ...state,
        // user: payload.user,
        user: payload.user || JSON.parse(sessionStorage.getItem("user")),
        isAuthenticated: !!sessionStorage.getItem("token"),
      };
    case LOGIN_FAIL:
      return {
        ...state,
        isAuthenticated: false,
      };

    case SSO_SUCCESS:
      console.log("payload", payload);
      return {
        ...state,
        // user: payload.user,
        // user: { roles: ["USER"], name: "Admin" },
        // isAuthenticated: payload.isAuthenticated,
      };

    case SSO_FAIL:
      return {
        ...state,
        isAuthenticated: false,
      };

    case LOGOUT_SUCCESS:
      return {
        ...state,
        isAuthenticated: false,
        user: null,
      };
    case LOGOUT_FAIL:
      return {
        ...state,
      };
    case LOAD_USER_SUCCESS:
      return {
        ...state,
        user: payload.user,
      };
    case LOAD_USER_FAIL:
      return {
        ...state,
        user: null,
      };
    case AUTHENTICATED_SUCCESS:
      return {
        ...state,
        isAuthenticated: true,
      };
    case AUTHENTICATED_FAIL:
      return {
        ...state,
        isAuthenticated: false,
        user: null,
      };
    case REFRESH_SUCCESS:
      return {
        ...state,
      };
    case REFRESH_FAIL:
      return {
        ...state,
        isAuthenticated: false,
        user: null,
      };
    case SET_AUTH_LOADING:
      return {
        ...state,
        loading: true,
      };
    case REMOVE_AUTH_LOADING:
      return {
        ...state,
        loading: false,
      };
    case SELECT_ROLE:
      console.log("payload", payload);
      return {
        ...state,
        roleSelection: payload.roleSelection,
        user: payload.user || JSON.parse(sessionStorage.getItem("user")),
      };
    default:
      return state;
  }
};

export default authReducer;
