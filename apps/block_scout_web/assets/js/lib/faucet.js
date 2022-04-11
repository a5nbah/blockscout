import $ from 'jquery'

$('#faucet-button').on('click', function (event) {
  requestFaucet();
})

function requestFaucet () {
  const address = $('#faucetAddress').val();
  if (!address || address === '') {
    return;
  }
  const q = address.trim();
  const requestOptions = {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  };
  fetch('https://test-rpc.aiax.network/faucet/give/?address=' + q, requestOptions)
    .then(async response => {
      const data = await response.json();
      if (response.ok) {
        console.log('Success faucet, transaction: ' + data.transaction);
        alert('Test coins successfully sent to the address ' + q + '\n\nTransaction: ' + data.transaction);
      } else {
        console.error('Error faucet, details: ' + JSON.stringify(data));
        switch (response.status) {
          case 503: alert('Reached faucet limit, please try later'); break;
          case 400: alert('Invalid address provided'); break;
          default: alert('An error occurred during request to faucet');
        }
      }
    })
    .catch(error => {
      console.error('Fetch error', error);
    });
};