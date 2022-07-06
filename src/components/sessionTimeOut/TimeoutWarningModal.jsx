import React from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";

import { logoutUser } from "../../store/actions/auth";

const TimeoutWarningModal = ({ isOpen, handleClick }) => {
  const navigate = useNavigate();
  const dispatch = useDispatch();

  const logout = () => {
    dispatch(logoutUser(navigate));
    handleClick();
  };

  return (
    <Modal show={isOpen} onHide={handleClick} size="sm" centered>
      <Modal.Body>
        <div>You are about to logout in 3 secs, Do you want to Continue?</div>
      </Modal.Body>

      <Modal.Footer>
        {/* <Button variant="secondary">No</Button> */}
        <Button variant="primary" onClick={logout}>
          Logout
        </Button>
        <Button variant="primary" onClick={handleClick}>
          Keep Logged In
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default TimeoutWarningModal;
