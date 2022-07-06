import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";

const Home = () => {
  const { loading, isAuthenticated, user } = useSelector((state) => state.auth);
  const navigate = useNavigate();

  // useEffect(() => {
  //   if (!isAuthenticated || !user) {
  //     navigate("/login");
  //   }
  // }, [isAuthenticated]);

  const accountInfo = sessionStorage.getItem("userdetails");

  const logout = () => {};

  return (
    <div>
      Home Page
      <p>
        <span>Welcome, {accountInfo}!</span>
        <button type="button" onClick={logout}>
          Logout
        </button>
      </p>
    </div>
  );
};

export default Home;
