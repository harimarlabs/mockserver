import React from "react";
import Loader from "../../assets/images/loader.webp";

const MainLoader = () => {
  return (
    <div className="vh-100 vw-100">
      <div className="d-flex justify-content-center align-items-center vh-100 ">
        {/* <div className="spinner-border">
          <span className="visually-hidden">Loading...</span>
        </div> */}
        <img src={Loader} alt="Loading ..." />
      </div>
    </div>
  );
};

export default MainLoader;
