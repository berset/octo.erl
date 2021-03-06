-module(octo_reference).
-include("octo.hrl").
-export([
  list/3, list_branches/3, list_tags/3,
  read/4, read_tag/4, read_branch/4,
  create/4, create_branch/5, create_tag/5,
  update/5,
  delete/4, delete_branch/4, delete_tag/4
]).

%% API

list(Owner, Repo, Options) -> list_references(reference, Owner, Repo, [{ skip_ref_modification }|Options]).
list_branches(Owner, Repo, Options) -> list_references(branch, Owner, Repo, Options).
list_tags(Owner, Repo, Options) -> list_references(tag, Owner, Repo, Options).

read(Owner, Repo, RefName, Options) -> read_reference(reference, Owner, Repo, RefName, [{ skip_ref_modification }|Options]).
read_tag(Owner, Repo, TagName, Options) -> read_reference(tag, Owner, Repo, TagName, Options).
read_branch(Owner, Repo, BranchName, Options) -> read_reference(branch, Owner, Repo, BranchName, Options).

create(Owner, Repo, Payload, Options) ->
  Url          = octo_url_helper:reference_url(Owner, Repo),
  PayloadJson  = jsonerl:encode(Payload),
  {ok, Result} = octo_http_helper:post(Url, Options, PayloadJson),
  {ok, ?json_to_record(octo_reference, Result)}.

create_branch(Owner, Repo, BranchName, Source, Options) ->
  {ok, Record} = create(Owner, Repo, {
    {<<"ref">>, list_to_binary("refs/heads/" ++ BranchName)},
    {<<"sha">>, list_to_binary(Source)}
  }, Options),
  {ok, truncate_ref(Record)}.

create_tag(Owner, Repo, TagName, Source, Options) ->
  {ok, Record} = create(Owner, Repo, {
    {<<"ref">>, list_to_binary("refs/tags/" ++ TagName)},
    {<<"sha">>, list_to_binary(Source)}
  }, Options),
  {ok, truncate_ref(Record)}.

update(Owner, Repo, "refs/" ++ RefName, Payload, Options) ->
  update(Owner, Repo, RefName, Payload, Options);
update(Owner, Repo, RefName, Payload, Options) ->
  Url          = octo_url_helper:reference_url(Owner, Repo, RefName),
  PayloadJson  = jsonerl:encode(Payload),
  {ok, Result} = octo_http_helper:patch(Url, Options, PayloadJson),
  {ok, ?json_to_record(octo_reference, Result)}.

delete(Owner, Repo, "refs/" ++ RefName, Options) ->
  delete(Owner, Repo, RefName, Options);
delete(Owner, Repo, RefName, Options) ->
  Url = octo_url_helper:reference_url(Owner, Repo, RefName),
  octo_http_helper:delete(Url, Options).

delete_branch(Owner, Repo, BranchName, Options) ->
  delete(Owner, Repo, "refs/heads/" ++ BranchName, Options).

delete_tag(Owner, Repo, TagName, Options) ->
  delete(Owner, Repo, "refs/tags/" ++ TagName, Options).

%% Internals

list_references(Type, Owner, Repo, Options) ->
  References = octo_http_helper:read_collection(Type, [Owner, Repo], Options),
  Result     = [ struct_to_record(Reference, Options) || (Reference) <- References ],
  {ok, Result}.

read_reference(Type, Owner, Repo, "refs/" ++ RefName, Options) ->
  read_reference(Type, Owner, Repo, RefName, Options);

read_reference(Type, Owner, Repo, RefName, Options) ->
  Fun           = list_to_atom(atom_to_list(Type) ++ "_url"),
  Url           = erlang:apply(octo_url_helper, Fun, [Owner, Repo, RefName]),
  {State, Json} = octo_http_helper:get(Url, Options),
  case State of
    ok -> {ok, struct_to_record(jsonerl:decode(Json), Options)};
    _  -> {State, Json}
  end.

struct_to_record(Struct, [{ skip_ref_modification }|_]) ->
  ?struct_to_record(octo_reference, Struct);

struct_to_record(Struct, _) ->
  Record = ?struct_to_record(octo_reference, Struct),
  truncate_ref(Record).

truncate_ref(Record) ->
  OldRef = Record#octo_reference.ref,
  NewRef = binary:replace(OldRef, [<<"refs/heads/">>, <<"refs/tags/">>], <<"">>),
  Record#octo_reference{ref=NewRef}.
