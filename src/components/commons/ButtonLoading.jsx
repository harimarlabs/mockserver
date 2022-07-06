import React from "react";
import { useSelector } from "react-redux";

const ButtonLoading = ({ title }) => {
  const { loading, isAuthenticated, user } = useSelector((state) => state.auth);

  return (
    <>
      {loading ? (
        <button disabled type="submit" className="btn btn-primary">
          <span className="spinner-border spinner-border-sm" />
          Loading...
        </button>
      ) : (
        <button type="submit" className="btn btn-primary">
          {title}
        </button>
      )}{" "}
    </>
  );
};

export default ButtonLoading;
