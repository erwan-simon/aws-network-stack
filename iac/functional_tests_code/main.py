import urllib.request


def main():
    """
    function which gets google and fails if it does not work
    """
    url = "https://www.google.com"
    with urllib.request.urlopen(url) as response:
        response.read().decode("utf-8")
        print("Statut :", response.getcode())
        if response.getcode() != 200:
            raise ValueError(f"Got error code {response.getcode()}")


def lambda_handler(event: dict, _: dict):
    main()
