// Run with `node tool/check-gallery-link.mjs`. Executes the gallery-link
// script from example/web/index.html against a small History API fixture.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const htmlPath = process.argv[2] ?? 'example/web/index.html';
const html = readFileSync(htmlPath, 'utf8');
const script = html.match(/<script>\s*([\s\S]*?gallery-link[\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'example/web/index.html has a gallery-link script');

function boot(initialHash) {
  const link = { hidden: true };
  const listeners = new Map();
  const location = { hash: initialHash };
  const entries = [initialHash];
  let index = 0;
  const dispatch = (type) => listeners.get(type)?.forEach((listener) => listener());
  const setUrl = (url) => {
    location.hash = new URL(url, 'https://example.test/').hash;
  };
  const history = {
    pushState(_state, _title, url) {
      entries.splice(index + 1);
      setUrl(url);
      entries.push(location.hash);
      index++;
    },
    replaceState(_state, _title, url) {
      setUrl(url);
      entries[index] = location.hash;
    },
    go(delta) {
      const oldHash = location.hash;
      index += delta;
      location.hash = entries[index];
      dispatch('popstate');
      if (oldHash !== location.hash) dispatch('hashchange');
    },
  };
  const addEventListener = (type, listener) => {
    const group = listeners.get(type) ?? new Set();
    group.add(listener);
    listeners.set(type, group);
  };
  vm.runInNewContext(script, {
    addEventListener,
    document: { getElementById: () => link },
    history,
    location,
  });
  return { dispatch, history, link, location };
}

const demo = boot('#/switcher');
assert.equal(demo.link.hidden, true, 'initial demo route hides gallery link');
const configurator = boot('#/configurator?c=lay:docked');
assert.equal(configurator.link.hidden, true, 'initial configurator route hides gallery link');
const home = boot('');
assert.equal(home.link.hidden, false, 'initial home route shows gallery link');
assert.equal(boot('#').link.hidden, false, 'empty hash home route shows gallery link');
assert.equal(boot('#/').link.hidden, false, 'slash hash home route shows gallery link');
assert.equal(boot('#/not-a-demo').link.hidden, true, 'unknown hash hides gallery link');

home.history.pushState(null, '', '/#/switcher');
assert.equal(home.location.hash, '#/switcher');
assert.equal(home.link.hidden, true, 'pushState to a demo hides gallery link');
home.history.replaceState(null, '', '/');
assert.equal(home.link.hidden, false, 'replaceState to home shows gallery link');
home.history.pushState(null, '', '/#/accessibility');
assert.equal(home.link.hidden, true, 'pushState to another demo hides gallery link');
home.history.go(-1);
assert.equal(home.link.hidden, false, 'back navigation to home shows gallery link');
home.history.go(1);
assert.equal(home.link.hidden, true, 'forward navigation to demo hides gallery link');
home.history.pushState(null, '', '/#/not-a-demo');
assert.equal(home.link.hidden, true, 'pushState to an unknown hash hides gallery link');

home.location.hash = '#/';
home.dispatch('hashchange');
assert.equal(home.link.hidden, false, 'native hashchange to home shows gallery link');
home.location.hash = '#/accessibility';
home.dispatch('hashchange');
assert.equal(home.link.hidden, true, 'native hashchange to a demo hides gallery link');
home.location.hash = '#/';
home.dispatch('popstate');
assert.equal(home.link.hidden, false, 'popstate alone refreshes the link');
console.log('Gallery-link route behavior passed.');
