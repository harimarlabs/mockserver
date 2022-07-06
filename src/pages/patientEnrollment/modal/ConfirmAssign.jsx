import React from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";

const ConfirmAssign = ({ isOpen, handleClick, setconfirmBox }) => {
  const isConfirmed = (check) => {
    setconfirmBox(check);
    handleClick();
  };

  return (
    <Modal show={isOpen} onHide={handleClick} size="sm" centered>
      <Modal.Body>
        <div>Do you want to Assign yourself as a Care Manager to Patient?</div>
      </Modal.Body>

      <Modal.Footer>
        <Button variant="secondary" onClick={(e) => isConfirmed(false)}>
          No
        </Button>
        <Button variant="primary" onClick={(e) => isConfirmed(true)}>
          {/* {setconfirmBox(!confirmBox)} */}
          Yes
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default ConfirmAssign;
