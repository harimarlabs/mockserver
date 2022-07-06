import React, { useState, useRef, useEffect } from "react";
import { Form, Row, Button, Modal } from "react-bootstrap";
import axios from "axios";

import { toast } from "react-toastify";
import { useNavigate } from "react-router-dom";

import API from "../../util/apiService";
// import UploadModal from "./modal/UploadModal";
import CalyxLoader from "../../components/commons/CalyxLoader";
import LongProcess from "../../components/commons/LongProcess";

const RiskAnalysis = () => {
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [docId, setDocId] = useState(0);

  const navigate = useNavigate();

  const uploadFile = async (uploadData) => {
    const formData = new FormData();
    formData.append("file", uploadData);

    const config = {
      headers: {
        "content-type": "multipart/form-data",
      },
    };
    // const data = await axios.post(UPLOAD_ENDPOINT, formData, config);
    const data = await API.post("/inboundintegration/api/v1.0/itedocument", formData, config);

    return data;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      toast.info("Upload is inprogress");

      const { data } = await uploadFile(file);
      setLoading(false);
      // toast.success("Uploaded Successfully");
      setDocId(data.id);
      // navigate("/patient-enrollment");
    } catch (error) {
      toast.error(`${error.response.data?.error}`);
      setLoading(false);
    }
  };

  return (
    <>
      <h1 className="h3 mb-3">Discharge Summary</h1>
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <div className="row">
                {/* <div className="col-3">
                  <h3 className="card-title">Patient List</h3>
                </div> */}
                <div className="col-12 pb-5">
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
                    </div>
                    <div className="py-4">
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
                  <LongProcess docid={docId} />

                  {/* <UploadModal handleClick={handleModalClick} isOpen={isModalOpen} /> */}

                  {/* {loading && <CalyxLoader />} */}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default RiskAnalysis;
