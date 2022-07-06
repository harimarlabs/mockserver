import React from "react";
import { useNavigate } from "react-router-dom";

const Unauthorized = () => {
  const navigate = useNavigate();

  const goBack = () => navigate(-1);

  const logOutHandle = () => {
    sessionStorage.removeItem("token");
    navigate("/login");
  };

  return (
    <section>
      <h1>Unauthorized</h1>
      <br />
      <p>You do not have access to the requested page.</p>
      <div className="flexGrow">
        <button type="button" onClick={goBack}>
          Go Back
        </button>
      </div>
      <div className="flexGrow">
        <button type="button" onClick={logOutHandle} className="btn btn-link">
          Sign out
        </button>
      </div>
    </section>
  );
};

export default Unauthorized;
