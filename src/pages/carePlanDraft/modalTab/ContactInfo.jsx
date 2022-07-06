import React from "react";

const ContactInfo = ({ register }) => {
  return (
    <div className="row mt-4">
      <div className="col-md-12">
        <div className="row">
          <div className="col-12">
            <div className="card card-info">
              <div className="card-body pe-2">
                <div className="row">
                  <div className="col-4 pe-2">
                    <div className="text-bold info-key pe-2 pb-3">Primary Care Physician</div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-care-physician" className="info-key">
                          Name
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-care-physician"
                          name="physician"
                          {...register("physician")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-care-physician-contact">Contact Number</label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-care-physician-contact"
                          name="physicianMobile"
                          {...register("physicianMobile")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-care-physician-email" className="info-key">
                          Email ID
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-care-physician-email"
                          name="physicianEmail"
                          {...register("physicianEmail")}
                        />
                      </div>
                    </div>
                  </div>
                  <div className="col-4 pe-2">
                    <div className="text-bold info-key pe-2 pb-3">Primary Case Manager</div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-case-manager" className="info-key">
                          Name
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <select
                          className="form-select form-select-sm w-100 info-val"
                          name="caseManager"
                          {...register("caseManager")}
                        >
                          <option>Clara J</option>
                          <option>Nick H</option>
                          <option>Johnson K</option>
                        </select>
                      </div>
                      <div className="col-1" />
                    </div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-case-manager-contact" className="info-key">
                          Contact Number
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-case-manager-contact"
                          name="caseManagerMobile"
                          {...register("caseManagerMobile")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-case-manager-email" className="info-key">
                          Email ID
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-case-manager-email"
                          name="caseManagerEmail"
                          {...register("caseManagerEmail")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                  </div>
                  <div className="col-4 pe-2">
                    <div className="text-bold info-key pe-2 pb-3">Primary Care Giver</div>
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-care-giver" className="info-key">
                          Name
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-care-giver"
                          name="careGiver"
                          {...register("careGiver")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                    <div className="col-2" />
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-care-giver-contact" className="info-key">
                          Contact Number
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-care-giver-contact"
                          name="careGiverMobile"
                          {...register("careGiverMobile")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                    <div className="col-2" />
                    <div className="row pb-2 d-flex">
                      <div className="col-4 text-bold pe-2 info-key">
                        <label htmlFor="primary-care-giver-email" className="info-key">
                          Email ID
                        </label>
                      </div>
                      <div className="col-7 info-val">
                        <input
                          type="text"
                          className="form-control form-control-sm w-100"
                          id="primary-care-giver-email"
                          name="careGiverEmail"
                          {...register("careGiverEmail")}
                        />
                      </div>
                      <div className="col-1" />
                    </div>
                  </div>
                  <div className="col-1" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ContactInfo;
