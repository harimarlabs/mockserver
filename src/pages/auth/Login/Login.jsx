import { useEffect } from "react";
import { useNavigate, Link, useLocation } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as Yup from "yup";
import ButtonLoading from "../../../components/commons/ButtonLoading";

import { loginUser } from "../../../store/actions/auth";
import AzureADAuth from "./AzureADAuth";

const Login = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { loading, isAuthenticated, user } = useSelector((state) => state.auth);

  // const from = location?.state?.from?.pathname || "/";
  const from = "/";

  const validationSchema = Yup.object().shape({
    loginId: Yup.string().required("User Name is required"),
    password: Yup.string()
      .required("Password is required")
      .min(4, "Password must be at least 6 characters")
      .max(40, "Password must not exceed 40 characters"),
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
    dispatch(loginUser(data, navigate));
  };

  // useEffect(() => {
  //   console.log(isAuthenticated, user);
  //   if (isAuthenticated && user) {
  //     navigate("/");
  //   }
  // }, [isAuthenticated]);

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
                  <div className="col-lg-6 bg-login-img  bg-info" />
                  <div className="col-lg-6">
                    <div className="p-5">
                      <div className="text-center">
                        <h4 className="h4 text-gray-900 mb-4">Login</h4>
                      </div>
                      <form onSubmit={handleSubmit(onSubmit)}>
                        <div className="form-group mb-3">
                          <label htmlFor="loginId">Username or Email</label>
                          <input
                            id="loginId"
                            name="loginId"
                            type="text"
                            placeholder="Username or Email"
                            {...register("loginId")}
                            className={`form-control form-control-md ${
                              errors.loginId ? "is-invalid" : ""
                            }`}
                          />
                          <div className="invalid-feedback">{errors.loginId?.message}</div>
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
                          <ButtonLoading title="Login" />
                        </div>
                      </form>
                      <hr />

                      <div>
                        <p className="small">
                          Dont have an account? <Link to="/signup">Create an Account</Link>
                        </p>
                      </div>

                      <div>
                        <AzureADAuth />
                      </div>
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

export default Login;
