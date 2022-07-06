import { useNavigate, Link } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as Yup from "yup";
import ButtonLoading from "../../../components/commons/ButtonLoading";

import { registerUser } from "../../../store/actions/auth";

const SignUp = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const validationSchema = Yup.object().shape({
    userName: Yup.string()
      .required("User Name is required")
      .min(6, "User Name must be at least 6 characters")
      .max(20, "User Name must not exceed 20 characters"),
    email: Yup.string().required("Email is required").email("Email is invalid"),
    password: Yup.string()
      .required("Password is required")
      .min(6, "Password must be at least 6 characters")
      .max(40, "Password must not exceed 40 characters"),
    confirmPassword: Yup.string()
      .required("Confirm Password is required")
      .oneOf([Yup.ref("password"), null], "Confirm Password does not match"),
    acceptTerms: Yup.bool().oneOf([true], "Accept Terms is required"),
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    resolver: yupResolver(validationSchema),
  });

  const onSubmit = (data) => {
    // dispatch(registerUser(data, navigate));

    const userData = {
      loginId: data.email,
      password: data.password,
    };

    dispatch(registerUser(userData, navigate));
  };
  return (
    <>
      <div className="container">
        {/* Outer Row */}
        <div className="row justify-content-center">
          <div className="col-xl-10 col-lg-12 col-md-9">
            <div className="card o-hidden border-0 shadow-lg my-5">
              <div className="card-body p-0">
                {/* Nested Row within Card Body */}
                <div className="row">
                  <div className="col-lg-6 d-none d-lg-block bg-login-img bg-info" />
                  <div className="col-lg-6">
                    <div className="p-5">
                      <div className="text-center">
                        <h4 className="h4 text-gray-900 mb-4">Sign Up</h4>
                      </div>
                      <form onSubmit={handleSubmit(onSubmit)}>
                        <div className="form-group mb-3">
                          <label htmlFor="uname">Username</label>
                          <input
                            id="uname"
                            name="userName"
                            type="text"
                            placeholder="Username"
                            {...register("userName")}
                            className={`form-control form-control-md ${
                              errors.userName ? "is-invalid" : ""
                            }`}
                          />

                          <div className="invalid-feedback">{errors.userName?.message}</div>
                        </div>

                        <div className="form-group mb-3">
                          <label htmlFor="email">Email</label>
                          <input
                            id="email"
                            name="email"
                            type="text"
                            placeholder="Email"
                            {...register("email")}
                            className={`form-control form-control-md ${
                              errors.email ? "is-invalid" : ""
                            }`}
                          />
                          <div className="invalid-feedback">{errors.email?.message}</div>
                        </div>

                        <div className="form-group mb-3">
                          <label htmlFor="password">Password</label>
                          <input
                            id="password"
                            name="password"
                            type="password"
                            placeholder="Password"
                            {...register("password")}
                            className={`form-control form-control-md ${
                              errors.password ? "is-invalid" : ""
                            }`}
                          />
                          <div className="invalid-feedback">{errors.password?.message}</div>
                        </div>
                        <div className="form-group mb-3">
                          <label htmlFor="confirmPassword">Confirm Password</label>
                          <input
                            id="confirmPassword"
                            name="confirmPassword"
                            type="password"
                            placeholder="Confirm Password"
                            {...register("confirmPassword")}
                            className={`form-control form-control-md ${
                              errors.confirmPassword ? "is-invalid" : ""
                            }`}
                          />
                          <div className="invalid-feedback">{errors.confirmPassword?.message}</div>
                        </div>

                        <div className="form-group mb-3 form-check">
                          <input
                            id="acceptTerms"
                            name="acceptTerms"
                            type="checkbox"
                            placeholder=""
                            {...register("acceptTerms")}
                            className={`form-check-input ${errors.acceptTerms ? "is-invalid" : ""}`}
                          />
                          <label htmlFor="acceptTerms" className="form-check-label">
                            I have read and agreed to the Terms
                          </label>
                          <div className="invalid-feedback">{errors.acceptTerms?.message}</div>
                        </div>

                        <div className="form-group mb-3 mt-3">
                          <ButtonLoading title="Register" /> &nbsp;
                          <button
                            type="button"
                            onClick={() => reset()}
                            className="btn btn-warning float-right"
                          >
                            Reset
                          </button>
                        </div>
                      </form>
                      <hr />

                      <div>
                        <p className="small">
                          Already have an account? <Link to="/login">Login</Link>
                        </p>
                        {/* <a className="small" href="register.html">
                          Create an Account!
                        </a> */}
                      </div>
                      {/* <div>
                        <Link className="small" to="/register">
                          Forgot Password?
                        </Link>
                      </div> */}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default SignUp;
