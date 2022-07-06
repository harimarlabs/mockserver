import React, { useEffect, useState } from "react";
import { Form, Row, Button, Modal } from "react-bootstrap";
import axios from "axios";
import { toast } from "react-toastify";
import { useNavigate } from "react-router-dom";

const UploadModal = ({ isOpen, handleClick }) => {
  const UPLOAD_ENDPOINT = "/inboundintegration/api/v1.0/itedocument";

  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const uploadFile = async (uploadData) => {
    const formData = new FormData();
    formData.append("file", uploadData);

    const config = {
      headers: {
        "content-type": "multipart/form-data",
      },
    };

    const data = await axios.post(UPLOAD_ENDPOINT, formData, config);

    return data;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    // setTimeout(() => {
    //   handleClick();
    // }, 3000);

    try {
      const { data } = await uploadFile(file);
      console.log("data", data);
      setLoading(false);

      toast.success("Uploaded Successfully");
      //   dispatch({
      //     type: LOGIN_SUCCESS,
      //     payload: data,
      //   });

      navigate("/patient-enrollment");

      //

      handleClick();
    } catch (error) {
      toast.error(`${error.response.data}`);
      setLoading(false);

      //   dispatch({
      //     type: LOGIN_FAIL,
      //     payload: error.response.data,
      //   });
    }
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
        <Modal.Title>Discharge Summary</Modal.Title>
      </Modal.Header>

      <Modal.Body>
        <form onSubmit={handleSubmit}>
          <div>
            <label htmlFor="formFileLg" className="form-label">
              Upload
            </label>
            <input
              className="form-control form-control-lg"
              id="formFileLg"
              type="file"
              onChange={(e) => setFile(e.target.files[0])}
            />

            {/* <button type="submit" className="btn btn-primary">
              X
            </button> */}
          </div>
          <div className="pt-3">
            {loading ? (
              <button type="submit" disabled className="btn btn-primary">
                Uploading ...
              </button>
            ) : (
              <button type="submit" className="btn btn-primary">
                Upload File
              </button>
            )}
          </div>
        </form>
      </Modal.Body>
    </Modal>
  );
};

export default UploadModal;
