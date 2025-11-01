defmodule Cubepub.Accounts do
  use Ash.Domain

  resources do
    resource(Cubepub.Accounts.User)
    resource(Cubepub.Accounts.Token)
  end
end
