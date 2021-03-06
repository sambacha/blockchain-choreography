import * as React from "react";

const buttonWidgetStyles = require("./ButtonWidget.css");

interface IButtonWidgetProps {
  firstButtonText: string;
  firstButtonOnClick: (e: React.MouseEvent<HTMLButtonElement>) => {};
  secondButtonText?: string;
  secondButtonOnClick?: (e: React.MouseEvent<HTMLButtonElement>) => {};
}

export default class ButtonWidget extends React.Component<IButtonWidgetProps, {}> {

  public render() {
    return (
      <div className={buttonWidgetStyles.buttonContainer}>
        <button className={buttonWidgetStyles.button} onClick={this.props.firstButtonOnClick}>
          {this.props.firstButtonText}
        </button>
        {
          this.props.secondButtonText ?
          <button className={buttonWidgetStyles.button} onClick={this.props.secondButtonOnClick}>
            {this.props.secondButtonText}
          </button> :
          undefined
        }
      </div>
    );
  }
}
