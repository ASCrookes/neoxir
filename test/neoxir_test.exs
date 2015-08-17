defmodule NeoxirTest do

  import Neoxir


  defmodule CreateSession do
    use ExUnit.Case, async: true

  # create_session

    test "create_session: returns a session struct" do
      session = create_session
      assert session.root_url == "http://localhost:7474/" 
      assert session.data_url == "http://localhost:7474/db/data/"
      assert String.valid?(session.root_resource["neo4j_version"])
    end

  end

  defmodule Commit do

    use ExUnit.Case, async: true
  
    setup_all do
      {:ok, %{session: create_session}}
    end

    # commit

    test "commit: single valid statement", %{session: session} do
      {:ok, [response]} = commit(session, statement: "CREATE (n) RETURN ID(n) as x")
      assert Dict.keys(response) == [:x]
      assert is_number(response[:x])
    end


    test "commit: with REST response", %{session: session}  do
      {:ok, [response]} = commit(session, statement: "CREATE (n {name: 'andreas'}) RETURN n", resultDataContents: [ "REST" ])
      assert response |> Dict.keys == [:n]
      assert response |> Dict.get(:n) |> Dict.get("data") == %{"name" => "andreas"}
    end


    test "commit: many valid statements", %{session: session} do
      statements = [
        [statement: "CREATE (n) RETURN ID(n) as x1"],
        [statement: "CREATE (n) RETURN ID(n) as x2"]
      ]

      {:ok, response} = commit(session, statements)

      [_, [second_result]] = response

      assert Dict.keys(second_result) == [:x2]
      assert is_number(second_result[:x2])
    end


    test "commit: single invalid statement", %{session: session} do
      {:error, Neoxir.CypherResponse, reason} = commit(session, statement: "CREATQQQ (n) RETURN ID(n) as x")
      assert reason["code"] == "Neo.ClientError.Statement.InvalidSyntax"
      assert Regex.match?(~r/Invalid input/, reason["message"])
    end


    test "commit: many invalid statements", %{session: session} do
      statements = [
        [statement: "QQCREATE (n) RETURN ID(n) as x1"],
        [statement: "AAAAREATE (n) RETURN ID(n) as x2"]
      ]

      {:error, _, [reason]} = commit(session, statements)
      assert reason["code"] == "Neo.ClientError.Statement.InvalidSyntax"
      assert Regex.match?(~r/Invalid input/, reason["message"])
    end

    # commit!

    test "commit!: single valid statement", %{session: session} do
      [response] = commit!(session, statement: "CREATE (n) RETURN ID(n) as x")
      assert Dict.keys(response) == [:x]
      assert is_number(response[:x])
    end


    test "commit!: invalid statement", %{session: session} do
      assert_raise Neoxir.CypherResponseError, ~r/Invalid input/, fn ->
        commit!(session, statement: "CCCCREATE (n) RETURN ID(n) as x")
      end    
    end
  end


end
