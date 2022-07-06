import React, { useState } from "react";
import { Link, useLocation } from "react-router-dom";

const SubMenu = ({ route }) => {
  const location = useLocation();
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* <li className={`${isOpen ? "menu-is-opening menu-open" : ""} nav-item`}>
        <Link
          to={route.path}
          className={`${location.pathname === route.path ? "active" : ""} nav-link`}
          onClick={() => setIsOpen(!isOpen)}
        >
          <span className="ms-1 d-none d-sm-inline">{route.name}</span>
          <span className="right">
            {isOpen ? <i className="bi bi-caret-down" /> : <i className="bi bi-caret-left" />}
          </span>
        </Link>
        {isOpen && (
          <ul className="nav nav-treeview">
            {route.routes.map((r) => (
              <li className="nav-item" key={r.name}>
                <Link
                  className={`${location.pathname === route.path ? "active" : ""} nav-link`}
                  to={r.path}
                >
                  <p>{r.name}</p>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </li> */}

      <li className={`${isOpen ? "active" : ""} sidebar-item`}>
        <Link to={route.path} className="sidebar-link" onClick={() => setIsOpen(!isOpen)}>
          <i className="align-middle" data-feather="sliders" />{" "}
          <span className="align-middle">Dashboards</span>
        </Link>

        {isOpen && (
          <ul className={`${isOpen ? "collapse show" : ""} sidebar-dropdown list-unstyled`}>
            {route.routes.map((r) => (
              <li
                className={`${location.pathname === r.path ? "active" : ""} sidebar-item`}
                key={r.name}
              >
                <Link className="sidebar-link" to={r.path}>
                  {r.name}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </li>
    </>
  );
};

export default SubMenu;
