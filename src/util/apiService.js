import axios from "axios";

const API_URL = "";

// const API_URL = `${process.env.REACT_APP_API_URL}`;

const headers = {
  "Content-Type": "application/json",
 //  "Access-Control-Allow-Origin": "http://localhost:3000",
  "Access-Control-Allow-Methods": "GET,PUT,POST,DELETE,PATCH,OPTIONS",
};
const instance = axios.create({
  baseURL: API_URL,
  headers,
  withCredentials: false,
});

instance.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem("token");
    if (token) {
      config.headers.Authorization = `Bearer${token}`;
    }
    // console.log("config===", config);
    return config;
  },
  (error) => {
    // console.log("error in axios", error);

    // if (error.response) {
    //   console.log('first')
    //   // The client was given an erroror response (5xx, 4xx)
    // } else if (error.request) {
    //   // The client never received a response, and the request was never left
    // } else {
    //   // Anything else
    // }

    Promise.reject(error);
  },
);

const API = {
  get: (path, params) => instance.get(path, params),
  post: (path, params) => instance.post(path, params),
  put: (path, params) => instance.put(path, params),
  patch: (path, params) => instance.patch(path, params),
  delete: (path, params) => instance.delete(path, params),
};

// API.interceptors.response.use((response) => { // block to handle success case
//     return response
//  }, function (error) { // block to handle error case
//     const originalRequest = error.config;

//     if (error.response.status === 401 && originalRequest.url ===
//  'http://dummydomain.com/auth/token') { // Added this condition to avoid infinite loop

//         // Redirect to any unauthorised route to avoid infinite loop...
//         return Promise.reject(error);
//     }

export default API;
