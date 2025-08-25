import React, {useState, FormEvent, Dispatch, useEffect} from "react";
import { OnChangeModel } from "../../common/types/Form.types";
import {useDispatch, useSelector} from "react-redux";
import {login} from "../../store/actions/account.actions";
import TextInput from "../../common/components/TextInput";
import Notifications from "../../common/components/Notification";
import {Link, useHistory} from "react-router-dom";
import useSession from "react-session-hook";
import Cookies from "js-cookie";


const Login: React.FC = () => {
  const dispatch: Dispatch<any> = useDispatch();
  const history = useHistory();

  const [formState, setFormState] = useState({
    email: { error: "", value: "" },
    password: { error: "", value: "" }
  });


  const state = useSelector((state: any) => state.account);
  const session = useSession();

  useEffect(() => {
    if (state.email !== '') {
      session.setSession({token: Cookies.get("token")});
      history.push('/');
    }
  }, [state.email, history, session]);

  function hasFormValueChanged(model: OnChangeModel): void {
    setFormState({ ...formState, [model.field]: { error: model.error, value: model.value } });
  }

  function submit(e: FormEvent<HTMLFormElement>): void {
    e.preventDefault();
    if(isFormInvalid()) { return; }
    dispatch(login(formState.email.value, formState.password.value));
  }

  function isFormInvalid() {
    return (formState.email.error || formState.password.error
        || !formState.email.value || !formState.password.value);
  }

  function getDisabledClass(): string {
    let isError: boolean = isFormInvalid() as boolean;
    return isError ? "disabled" : "";
  }

  return (

      <div className="container">
        <Notifications/>
        <div className="row justify-content-center">
          <div className="col-xl-10 col-lg-12 col-md-9">
            <div className="card o-hidden border-0 shadow-lg my-5">
              <div className="card-body p-0">
                <div className="row">
                  <div className="col-lg-6 d-none d-lg-block bg-login-image"></div>
                  <div className="col-lg-6">
                    <div className="p-5">
                      <div className="text-center">
                        <h1 className="h4 text-gray-900 mb-4">Welcome!</h1>
                      </div>
                      <form className="user" onSubmit={submit}>
                        <div className="form-group">

                          <TextInput id="input_email"
                                     field="email"
                                     value={formState.email.value}
                                     onChange={hasFormValueChanged}
                                     required={true}
                                     maxLength={100}
                                     label="Email"
                                     placeholder="Email" />
                        </div>
                        <div className="form-group">
                          <TextInput id="input_password"
                                     field="password"
                                     value={formState.password.value}
                                     onChange={hasFormValueChanged}
                                     required={true}
                                     maxLength={100}
                                     type="password"
                                     label="Password"
                                     placeholder="Password" />
                        </div>
                        <div className="form-group">
                          <div className="custom-control custom-checkbox small">
                            <input type="checkbox" className="custom-control-input" id="customCheck" />
                            <label className="custom-control-label"
                                   htmlFor="customCheck">Remember Me</label>
                          </div>
                        </div>
                        <button
                            className={`btn btn-primary btn-user btn-block ${getDisabledClass()}`}
                            type="submit">
                          Login
                        </button>
                      </form>
                      <div className="text-center">
                        <Link to={"/register"}>
                          No account ?
                        </Link>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
  );
};

export default Login;
