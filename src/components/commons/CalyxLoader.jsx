import React from "react";
import Loader from "../../assets/images/loader.webp";

const CalyxLoader = () => {
  return (
    <div className="vh-100 vw-100 modal-backdrop show">
      <div className="d-flex justify-content-center align-items-center vh-100 ">
        {/* <div className="spinner-border">
          <span className="visually-hidden">Loading...</span>
        </div> */}
        <img src={Loader} alt="Loading ..." />
      </div>
    </div>
  );
};

export default CalyxLoader;
