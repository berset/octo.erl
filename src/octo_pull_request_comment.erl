-module(octo_pull_request_comment).
-include("octo.hrl").
-export([
  %list/3, read/4, list_commits/4, list_files/4, is_merged/4, create/4, update/5, merge/4
  create/5
]).

%% API

list(Owner, Repo, Options) ->
  PullRequests = octo_http_helper:read_collection(pull_request, [Owner, Repo], Options),
  Result       = [ ?struct_to_record(octo_pull_request, PullRequest) || (PullRequest) <- PullRequests ],
  {ok, Result}.

read(Owner, Repo, Number, Options) ->
  Url        = octo_url_helper:pull_request_url(Owner, Repo, Number),
  {ok, Json} = octo_http_helper:get(Url, Options),
  Result     = ?json_to_record(octo_pull_request, Json),
  {ok, Result}.

list_commits(Owner, Repo, Number, Options) ->
  Commits = octo_http_helper:read_collection(pull_request_commits, [Owner, Repo, Number], Options),
  Result  = [ ?struct_to_record(octo_commit, Commit) || (Commit) <- Commits ],
  {ok, Result}.

list_files(Owner, Repo, Number, Options) ->
  Files  = octo_http_helper:read_collection(pull_request_files, [Owner, Repo, Number], Options),
  Result = [ ?struct_to_record(octo_file, File) || (File) <- Files ],
  {ok, Result}.

is_merged(Owner, Repo, Number, Options) ->
  Url        = octo_url_helper:pull_request_merged_url(Owner, Repo, Number),
  StatusCode = octo_http_helper:get_response_status_code(Url, Options),
  Result     = case StatusCode of
    404 -> false;
    204 -> true
  end,
  {ok, Result}.

create(Owner, Repo, Number, Payload, Options) ->
  Url          = octo_url_helper:pull_request_comments_url(Owner, Repo, Number),
  PayloadJson  = jsonerl:encode(Payload),
  {ok, Result} = octo_http_helper:post(Url, Options, PayloadJson),
  {ok, Result}.
  %%{ok, ?json_to_record(octo_pull_request, Result)}.

update(Owner, Repo, Number, Payload, Options) ->
  Url          = octo_url_helper:pull_request_url(Owner, Repo, Number),
  PayloadJson  = jsonerl:encode(Payload),
  {ok, Result} = octo_http_helper:patch(Url, Options, PayloadJson),
  {ok, ?json_to_record(octo_pull_request, Result)}.

merge(Owner, Repo, Number, Options) ->
  Url = octo_url_helper:merge_pull_request_url(Owner, Repo, Number),
  octo_http_helper:put(Url, Options, jsonerl:encode({})).
