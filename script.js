function createNode(element) {
      return document.createElement(element);
  }

  function append(parent, el) {
    return parent.appendChild(el);
  }

  const ul = document.getElementById('authors');
  const url = 'https://randomuser.me/api/?results=10';
  fetch(url)
  .then((resp) => resp.json())
  .then(function(data) {
    let authors = data.results;
    return authors.map(function(author) {
      let li = createNode('li'),
          img = createNode('img'),
          span = createNode('span');
          h2 = createNode('h2');
          h4  = createNode('h4');
          h5 = createNode('h5');
      img.src = author.picture.large;
      h2.innerHTML = `${author.name.first} ${author.name.last}`;
      h4.innerHTML = author.email;
      h5.innerHTML = author.cell;
      append(li, h2);
      append(li, h4);
      append(li, h5);
      append(li, img);
      append(ul, li);
    })
  })
  .catch(function(error) {
    console.log(error);
  });