import React from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";
import moment from "moment";

const PreviousDetails = ({ data, isOpen, handleClick }) => {
  const options = {
    year: "numeric",
    month: "numeric",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
    second: "numeric",
  };

  return (
    <Modal show={isOpen} onHide={handleClick} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Previous Contact Info </Modal.Title>
      </Modal.Header>

      <Modal.Body>
        <table className="table table-striped">
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Address</th>
              <th scope="col">Mobile No</th>
              <th scope="col">Emergency Contact</th>
              <th scope="col">Emergency Contact No</th>
              <th scope="col">Date & Time</th>
            </tr>
          </thead>
          <tbody>
            {data.map((item, index) => (
              <tr key={item.id}>
                <th scope="row">{index + 1}</th>
                <td>{item.address}</td>
                <td>{item.phone}</td>
                <td>{item.emergencyContactPerson}</td>
                <td>{item.emergencyContactNo}</td>
                <td>{moment(item.creationDate).format("MM/DD/YYYY")}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Modal.Body>
    </Modal>
  );
};

export default PreviousDetails;
