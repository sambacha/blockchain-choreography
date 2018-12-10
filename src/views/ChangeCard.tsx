import * as React from "react";
import * as TruffleContract from "truffle-contract";
import * as Web3 from "web3";

import ContractInteractionWidget from "@/components/ContractInteractionWidget";
import MessageHistory, { IMessageHistoryEntry } from "@/components/MessageHistory";
import StackedDate from "@/components/StackedDate";
import StackedUser from "@/components/StackedUser";
import IChoreography, { States } from "@/contract-interfaces/IChoreography";
import User from "@/util/User";

const ChoreographyContract = TruffleContract(require("../../build/contracts/Choreography.json"));

const changeCardStyles = require("./ChangeCard.css");

interface IChangeCardProps {
  web3: Web3;
}

interface IChangeCardState {
  account: string;
  accountError: boolean;
  timestamp: Date;
  diff: string;
  state: States;
  proposer: User;
  messages: IMessageHistoryEntry[];
  contract: IChoreography;
}

export default class ChangeCard extends React.Component<IChangeCardProps, IChangeCardState> {
  constructor(props) {
    super(props);

    this.state = {
      account: "",
      accountError: false,
      timestamp: new Date(),
      diff: "",
      state: States.READY,
      proposer: User.emptyUser(),
      messages: [],
      contract: undefined,
    };
  }

  public async componentWillMount() {
    let timestamp: Date = new Date();
    let publicKey: string = "";
    let diff: string = "";
    let state: States = States.READY;

    const instance: IChoreography = await this.initializeContract();

    // Get current change values
    timestamp = new Date(await instance.timestamp() * 1000);
    publicKey = await instance.proposer();
    diff = await instance.diff();
    const stateNumber = await instance.state();
    state = stateNumber.toNumber();

    const proposer = await User.build(publicKey, "friedow");
    const user2 = await User.build("x", "MaximilianV");
    const user3 = await User.build("x", "bptlab");
    const messages: IMessageHistoryEntry[] = [
      {
        user: proposer,
        message: "proposed a change to the \"Card Design\" diagram",
        timestamp: new Date(2018, 11, 0, 9),
      },
      {
        user: user2,
        message: "approved this change",
        timestamp: new Date(2018, 11, 0, 11),
      },
      {
        user: user3,
        message: "approved this change",
        timestamp: new Date(2018, 11, 1, 12),
      },
    ];

    this.setState({
      account: this.props.web3.eth.accounts[0],
      accountError: false,
      timestamp,
      diff,
      state,
      proposer,
      messages,
      contract: instance,
    });
  }

  public async initializeContract(): Promise<IChoreography> {
    if (this.props.web3.eth.accounts.length === 0) {
      this.setState({
        account: "",
        accountError: true,
      });
      return;
    }

    // Initialize contract
    ChoreographyContract.setProvider(this.props.web3.currentProvider);
    ChoreographyContract.defaults({
      from: this.props.web3.eth.accounts[0],
      gas: 5000000,
    });

    // Initialize contract instance
    let instance: IChoreography;
    instance = await ChoreographyContract.new("friedow", "friedow@example.org");
    return instance;
  }

  public render() {
    return (
    <div className={changeCardStyles.card}>
      <div className={changeCardStyles.cardLeft}>
        <div className={changeCardStyles.cardContent}>
          <img
            className={changeCardStyles.changedModel}
            src="https://bpmn.io/assets/attachments/blog/2016/019-colors.png"
          />
        </div>

        <div className={changeCardStyles.cardFooter}>
          <StackedDate timestamp={this.state.timestamp} />
          <StackedUser user={this.state.proposer} />
        </div>
      </div>

      <div className={changeCardStyles.cardRight}>
        <h1 className={changeCardStyles.changeDescription}>New Design for the current change card</h1>
        <MessageHistory messages={this.state.messages} />
        <ContractInteractionWidget contract={this.state.contract} contractState={this.state.state} />
      </div>
    </div>
    );
  }
}
