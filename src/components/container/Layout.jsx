import React, { useState } from "react";
import { Outlet } from "react-router-dom";
import {
  Nav,
  Navbar,
  NavItem,
  NavLink,
  Row,
  Col,
  Container,
  Form,
  FormControl,
  Button,
} from "react-bootstrap";
import Sidebar from "../sidebar/Sidebar";
import Header from "../header/Header";
// import Breadcrumb from "../commons/Breadcrumb";

const Layout = () => {
  const [openSidebar, setOpenSidebar] = useState(true);

  const onToggleSidebar = () => {
    setOpenSidebar(!openSidebar);
  };

  return (
    <>
      <div className="wrapper">
        {openSidebar && <Sidebar />}
        <div className="main">
          <Header onToggleSidebar={onToggleSidebar} />
          <div className="content">
            <div className="container-fluid p-0">
              <Outlet />
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Layout;
