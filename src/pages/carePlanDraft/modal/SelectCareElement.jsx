import React from "react";
import Modal from "react-bootstrap/Modal";
import Button from "react-bootstrap/Button";

const SelectCareElement = ({ isOpen, handleClick }) => {
  const [availableItems, setAvailableItems] = React.useState([
    {
      recommendations: "Monitor Vitals",
      careElement: "tempreture",
      selected: false,
    },
    {
      recommendations: "Medication",
      careElement: "Medicine to reduce cholestero",
      selected: false,
    },
    {
      recommendations: "Physiotherapy",
      careElement: "Cardio Physiotherapy",
      selected: false,
    },
  ]);

  const [selectedItems, setSelectedItems] = React.useState([]);

  const handleOnChange = (index) => {
    availableItems[index].selected = !availableItems[index].selected;
  };

  const handleChange = (index) => {
    selectedItems[index].selected = !selectedItems[index].selected;
  };

  const moveSelectedItems = () => {
    const upArr = availableItems.filter((el) => el.selected === false);
    const newArr = availableItems.filter((el) => el.selected === true);
    setAvailableItems(upArr);
    setSelectedItems((prevState) => [...prevState, ...newArr]);
  };

  const moveAvailableItems = () => {
    const getAvailableItems = selectedItems.filter((el) => el.selected === true);
    const newArr = selectedItems.filter((el) => el.selected === false);
    setSelectedItems(getAvailableItems);
    setAvailableItems((prevState) => [...prevState, ...newArr]);
  };

  return (
    <Modal
      show={isOpen}
      onHide={handleClick}
      size="lg"
      aria-labelledby="contained-modal-title-vcenter"
      centered
    >
      <Modal.Header closeButton>
        <Modal.Title>Select Care Elements</Modal.Title>
      </Modal.Header>

      <Modal.Body>
        <div className="card-body p-0">
          <div className="row d-flex">
            <div className="col-5">
              <div>
                <h4>Available</h4>
                <table className="table text-black-100">
                  <thead>
                    <tr>
                      <th scope="col">Select</th>
                      <th scope="col">Recommendations</th>
                      <th scope="col">Care Element</th>
                    </tr>
                  </thead>
                  <tbody>
                    {availableItems.map((item, index) => {
                      return (
                        <tr key={item.recommendations}>
                          <td>
                            <input
                              type="checkbox"
                              id="checkItem"
                              onChange={() => handleOnChange(index)}
                            />
                          </td>
                          <td>{item.recommendations}</td>
                          <td>{item.careElement}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="col-1 align-self-center" style={{ marginLeft: "0px" }}>
              <Button
                style={{ marginBottom: "1rem" }}
                className="btn btn-secondary rounded-circle"
                onClick={moveSelectedItems}
              >
                <i className="bi bi-arrow-right-circle-fill" />
              </Button>

              <Button className="btn btn-secondary rounded-circle" onClick={moveAvailableItems}>
                <i className="bi bi-arrow-left-circle-fill" />
              </Button>
            </div>

            {/* // Selected */}
            <div className="col-6">
              <h4>Selected</h4>
              <table className="table text-black-100">
                <thead>
                  <tr>
                    <th scope="cols">Select</th>
                    <th scope="col">Recommendations</th>
                    <th scope="col">Care Element</th>
                  </tr>
                </thead>
                <tbody>
                  {selectedItems.map((item, index) => {
                    return (
                      <tr key={item.recommendations}>
                        <td>
                          <input
                            type="checkbox"
                            id="checkItem"
                            onChange={() => handleChange(index)}
                          />
                        </td>
                        <td>{item.recommendations}</td>
                        <td>{item.careElement}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <Modal.Footer>
          <Button variant="primary" onClick={handleClick}>
            Confirm
          </Button>
          <Button variant="secondary" onClick={handleClick}>
            Exit
          </Button>
        </Modal.Footer>
      </Modal.Body>
    </Modal>
  );
};

export default SelectCareElement;
// rafce
